//
//  AWSClient.swift
//  K8sCat
//
//  Created by 顾艳华 on 2023/1/6.
//

import Foundation
import SotoEKS
import SotoSTS

struct MyAWSClient {
    
    
    let ak: String
    let sk: String
    let region: String
    let clusterName: String
    
    
    static let TOKEN_PREFIX = "k8s-aws-v1."
    func getCluster() -> AWSCluster{
        let client = AWSClient(
            credentialProvider: .static(accessKeyId: ak, secretAccessKey: sk),
            httpClientProvider: .createNew
        )
        var eks: EKS?
        switch region {
        case "us-west-1": eks = EKS(client: client, region: .uswest1)
        default: break
        }
//        let eks = EKS(client: client, region: .uswest1)
        let r = EKS.DescribeClusterRequest(name: clusterName)
        let c = try! eks!.describeCluster(r).wait().cluster
        let server = c?.endpoint
        let ca = c?.certificateAuthority?.data
//        print("sever: \(server!) ca: \(ca!)")
        try! client.syncShutdown()
        return AWSCluster(sever: server!, ca: ca!)
    }

    func getToken() -> String {
        let client = AWSClient(
            credentialProvider: .static(accessKeyId: ak, secretAccessKey: sk),
            httpClientProvider: .createNew
        )
        let sts = STS(client: client, region: .uswest1)
        let url = try! sts.signURL(
            url: URL(string: sts.endpoint+"/?Action=GetCallerIdentity&Version=2011-06-15")!,
            httpMethod: .GET,
            headers: ["x-k8s-aws-id": clusterName],
            expires: .seconds(60)
        ).wait()
//        print("signed: \(url.absoluteString)")
        var token = MyAWSClient.TOKEN_PREFIX + Base64FS.encodeString(str: url.absoluteString)
        token.remove(at: token.index(before: token.endIndex))
        token.remove(at: token.index(before: token.endIndex))
//        print("sts: \(token)")
        try! client.syncShutdown()
        return token
    }
}

struct AWSCluster {
    let sever: String
    let ca: String
}
