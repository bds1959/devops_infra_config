/*
Copyright 2022 The Kubernetes Authors.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package removefailedpods

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"sigs.k8s.io/descheduler/pkg/api"
)

// +k8s:deepcopy-gen=true
// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// RemoveFailedPodsArgs holds arguments used to configure RemoveFailedPods plugin.
type RemoveFailedPodsArgs struct {
	metav1.TypeMeta `json:",inline"`

	Namespaces              *api.Namespaces       `json:"namespaces"`
	LabelSelector           *metav1.LabelSelector `json:"labelSelector"`
	ExcludeOwnerKinds       []string              `json:"excludeOwnerKinds"`
	MinPodLifetimeSeconds   *uint                 `json:"minPodLifetimeSeconds"`
	Reasons                 []string              `json:"reasons"`
	IncludingInitContainers bool                  `json:"includingInitContainers"`
}
