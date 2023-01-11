//
//  DaemonView.swift
//  K8sCat
//
//  Created by 顾艳华 on 2022/12/26.
//

import SwiftUI

struct DaemonView: View {
    let daemon: Daemon
    let viewModel: ViewModel
    
    @State var showYaml = false
    var body: some View {
        Form {
            Section(header: "Name") {
                Text(daemon.name)
            }
            Section(header: "Status") {
                Text(daemon.status ? "Ready" : "Schedule")
            }
            Section(header: "Pods") {
                List {
                    ForEach(viewModel.model.podsByDaemon(in: .namespace(viewModel.ns), daemon: daemon.k8sName, name: daemon.name)) {
                        i in
                        NavigationLink {
                            PodView(pod: i, viewModel: viewModel)
                        } label: {
                            Image(systemName: "tray.2")
                            VStack(alignment: .leading) {
                                Text(i.name).foregroundColor(i.status == PodStatus.Failed.rawValue ? .red : (i.status == PodStatus.Running.rawValue || i.status == PodStatus.Succeeded.rawValue ? .green : .yellow))
                                HStack{
                                    Text("containers -").font(.caption)
                                    CaptionText(text: "expect: \(i.expect), ")
                                    CaptionText(text: "warning: \(i.warning)").foregroundColor(i.warning > 0 ? .red : .none)
                                }
                                
                            }
                        }
                    }
                }
            }
            Section(header: "Labels and Annotations") {
                NavigationLink {
                    List {
                        ForEach((daemon.labels ?? [:]).sorted(by: >), id: \.key) {
                            key, value in
                            VStack(alignment: .leading) {
                                Text(key)
                                
                                CaptionText(text: value)
                            }
                        }
                    }
                    
                } label: {
                    Text("Labels")
                }
                NavigationLink {
                    List {
                        ForEach((daemon.annotations ?? [:]).sorted(by: >), id: \.key) {
                            key, value in
                            VStack(alignment: .leading) {
                                Text(key)
                                CaptionText(text: value)
                            }
                        }
                    }
                } label: {
                    Text("Annotations")
                }
            }
           
            Section(header: "Misc") {
                HStack{
                    Text("Namespace")
                    Spacer()
                    Text(daemon.namespace)
                }
                
            }
        }.toolbar{
            Menu {
                Button {
                    // do something
                    let yaml = daemon.encodeYaml(client: viewModel.model.client)
                    print("Yaml: \(yaml)")
                    showYaml = true
//                    deployment.decodeYaml(client: viewModel.model.client, yaml: yaml)
                } label: {
                    Text("View/Edit Yaml")
                    Image(systemName: "note.text")
                }
//                Button {
//                    // do something
//                } label: {
//                    Text("Delete Resource")
//                    Image(systemName: "trash")
//                }
            } label: {
                 Image(systemName: "ellipsis")
            }
        }.sheet(isPresented: $showYaml){
            #if os(iOS)
            YamlWebView(yamlble: daemon, model: viewModel.model) {
                showYaml = false
            }
            #endif
            Button{
                urlScheme(yamlble: daemon, client: viewModel.model.client)
            }label: {
                Text("Load yaml via Yamler")
            }.padding()
        }
    }
}

struct DaemonView_Previews: PreviewProvider {
    static var previews: some View {
        DaemonView(daemon: Daemon(id: "123", name: "123", k8sName: [:], labels: ["l1":"l1v"],annotations: ["a1":"a1v"],namespace: "default", status: true, raw: nil), viewModel: ViewModel(viewContext: PersistenceController.preview.container.viewContext))
    }
}
