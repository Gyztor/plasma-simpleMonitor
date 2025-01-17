/**
 * Copyright 2013-2016 Dhaby Xiloj, Konstantin Shtepa
 *
 * This file is part of plasma-simpleMonitor.
 *
 * plasma-simpleMonitor is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation, either
 * version 3 of the License, or any later version.
 *
 * plasma-simpleMonitor is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with plasma-simpleMonitor.  If not, see <http://www.gnu.org/licenses/>.
 **/

import QtQuick 2.9
import QtQuick.Layouts 1.4
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Controls 2.2

import "../code/code.js" as Code

Rectangle {
    id: root

    width: implicitWidth
    height: implicitHeight

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Plasmoid.preferredRepresentation: plasmoid.fullRepresentation

    color: "black"

    // Control for atk sensor.
    property bool atkPresent: false

    Component.onCompleted: atkPresent = false

    // Configuration properties.
    property bool showGpuTemp:      plasmoid.configuration.showGpuTemp
    property double updateInterval: plasmoid.configuration.updateInterval

    QtObject {
        id: confEngine

        // Configuration properties.
        property int skin:              plasmoid.configuration.skin
        property int bgColor:           plasmoid.configuration.bgColor
        property int logo:              plasmoid.configuration.logo
        property bool showGpuTemp:      plasmoid.configuration.showGpuTemp
        property bool showSwap:         plasmoid.configuration.showSwap
        property bool showUptime:       plasmoid.configuration.showUptime
        property int tempUnit:          plasmoid.configuration.tempUnit
        property int cpuHighTemp:       plasmoid.configuration.cpuHighTemp
        property int cpuCritTemp:       plasmoid.configuration.cpuCritTemp
        property int cpuMaxVisible:     plasmoid.configuration.cpuMaxVisible
        property bool coloredCpuLoad:   plasmoid.configuration.coloredCpuLoad
        property bool flatCpuLoad:      plasmoid.configuration.flatCpuLoad
        property int indicatorHeight:   plasmoid.configuration.indicatorHeight
        property double updateInterval: plasmoid.configuration.updateInterval

        property string distroName: "tux"
        property string distroId: "tux"
        property string distroVersion: ""
        property string kernelName: ""
        property string kernelVersion: ""

        property int direction: Qt.LeftToRight

        onSkinChanged: {
            switch (skin) {
            default:
            case 0:
                loader.source = "skins/DefaultSkin.qml";
                root.Layout.maximumWidth = root.Layout.preferredWidth;
                root.Layout.maximumHeight = root.Layout.preferredHeight;
                root.Layout.maximumWidth = Number.POSITIVE_INFINITY;
                root.Layout.maximumHeight = Number.POSITIVE_INFINITY;
                break;
            case 1:
                loader.source = "skins/ColumnSkin.qml"
                root.Layout.maximumWidth = root.Layout.preferredWidth;
                root.Layout.maximumHeight = root.Layout.preferredHeight;
                root.Layout.maximumWidth = Number.POSITIVE_INFINITY;
                root.Layout.maximumHeight = Number.POSITIVE_INFINITY;
                break;
            case 2:
                loader.source = "skins/MinimalisticSkin.qml"
                root.Layout.maximumWidth = root.Layout.preferredWidth;
                root.Layout.maximumHeight = root.Layout.preferredHeight;
                root.Layout.maximumWidth = Number.POSITIVE_INFINITY;
                root.Layout.maximumHeight = Number.POSITIVE_INFINITY;
                break;
            }
        }

        onBgColorChanged: {
            switch (bgColor) {
            default:
            case 0:
                root.color = "black";
                plasmoid.backgroundHints = "StandardBackground";
                break;
            case 1:
                root.color = "transparent";
                plasmoid.backgroundHints = "NoBackground";
                break;
            case 2:
                root.color = "transparent";
                plasmoid.backgroundHints = "TranslucentBackground";
                break;
            }
        }

        Component.onCompleted: {
            Code.getDistroInfo(function(info) {
                distroName = info['name']
                distroId = info['id']
                if (info['version'] != undefined) {
                  distroVersion = info['version'];
                } else if (info['build_id'] != undefined){
                  distroVersion = info['build_id']; // e.g., Arch
                }
            }, this);

            Code.getKernelInfo(function(info){
                kernelName = info['name']
                kernelVersion = info['version']
            }, this);
        }
    }

    ListModel {
        id: cpuModel

        function getAll() {
            let list = [];
            for(let i=0; i < cpuModel.count; i++) {
                list.push(cpuModel.get(i));
            }
            return list;
        }
    }

    ListModel {
        id: coreTempModel

        function getAll() {
            let list = [];
            for(let i=0; i < coreTempModel.count; i++) {
                list.push(coreTempModel.get(i));
            }
            return list;
        }
    }

    ListModel {
        id: gpuTempModel
    }

    PlasmaCore.DataSource {
        id: systemInfoDataSource
        engine: "systemmonitor"
        interval: updateInterval * 1000

        property alias delegate: loader.item

        function tryAddSource(source) {
            if (connectedSources.indexOf(source) !== -1)
                return;

            // connect to cpu load sources
            if (source.match("^cpu/cpu\\d+/TotalLoad")) {
                connectSource(source);
                return;
            }

            // connect to cpu temp sources
            if (source.match("^lmsensors/coretemp-isa-\\d+/Core_\\d+")) {
                connectSource(source);
                return;
            }
            if (source.match("^lmsensors/k\\d+temp-pci-.+/.+")) {
                /* if atk is present then not connect */
                if (!root.atkPresent) {
                    connectSource(source);
                }
                return;
            }
            if (source.match("^lmsensors/coretemp-isa-\\d+/Package_id_\\d+")) {
                connectSource(source);
                return;
            }
            /* Try using ISA for some AMD chipsets */
            if (source.match("^lmsensors/nct\\d+-isa-.+/CPUTIN")) {
                if (!root.atkPresent) {
                  connectSource(source);
                }
                root.atkPresent = true;
                return;
            }

            /* Some AMD sensors works better with atk data*/
            if (source.match("^lmsensors/atk\\d+-acpi-\\d/CPU_Temperature")) {
                /* Remove k# temp sensors previously connected*/
                if (!root.atkPresent) {
                    for (i in connectedSources) {
                        if (i.match("^lmsensors/k\\d+temp-pci-.+/.+")) {
                            disconnectSource(i);
                            coreTempModel.clear();
                        }

                    }
                }
                root.atkPresent = true;
                connectSource(source);
                return;
            }

            // connect memory sources
            if (source.match("^mem/.*")) {
                connectSource(source);
                return;
            }

            // connect uptime source
            if (source.match("^system/uptime")) {
                connectSource(source);
                return;
            }
        }

        onSourceAdded: tryAddSource(source)

        onNewData: {
            if (data.value === undefined || delegate === undefined)
                return;

            // cpu load
            if (sourceName.match("^cpu/cpu\\d+/TotalLoad")) {
                var cpuNumber = sourceName.split('/')[1].match(/\d+/);
                if (confEngine.cpuMaxVisible)
                    cpuNumber = Math.min(cpuNumber, confEngine.cpuMaxVisible - 1)
                if (cpuModel.count <= cpuNumber)
                    cpuModel.append({'val': data.value});
                else {
                    var cpuNr = parseInt(sourceName.replace("cpu/cpu", "").replace("/TotalLoad", ""))
                    if (confEngine.cpuMaxVisible) {
                        if (cpuNr < confEngine.cpuMaxVisible)
                          cpuModel.set(cpuNumber, {'val': data.value});
                        else
                          cpuModel.remove(cpuModel.count - 1)
                    } else
                        cpuModel.set(cpuNumber, {'val': data.value});
                }
                return;
            }

            // cpu temp
            if (sourceName.match("^lmsensors/coretemp-isa-\\d+/Core_\\d+")
                    || sourceName.match("^lmsensors/coretemp-isa-\\d+/Package_id_\\d+")
                    || sourceName.match("^lmsensors/k\\d+temp-pci-.+/.+")
                    || sourceName.match("^lmsensors/atk\\d+-acpi-\\d/CPU_Temperature")
                    || sourceName.match("^lmsensors/nct\\d+-isa-.+/CPUTIN")) {
                var dataName = "0";
                var coreLabelStr = ""
                if (root.atkPresent) {
                    dataName=sourceName.replace(/^lmsensors\/atk\\d+-acpi-/i,"").replace(/\/CPU_Temperature/i,"")*1 + 1;
                } else if(sourceName.match("^lmsensors/k10temp-pci-.+/.+")) {
                    dataName = Code.k10CoreIndex(sourceName.replace(/^lmsensors\/k10temp-pci-/i,""))*1 + 1;
                    coreLabelStr = sourceName.replace(/^lmsensors\/k10temp-pci-.+\//i,"")*1 + 1;
                } else if(sourceName.match("^lmsensors/nct\\d+-isa-.+/CPUTIN")
                       || sourceName.match("^lmsensors/coretemp-isa-\\d+/Package_id_\\d+")) {
                    dataName = 0;
                    coreLabelStr = "CPU Package"
                } else {
                    dataName=data.name.split(' ')[1]*1 + 1;
                }

                if (coreTempModel.count <= dataName)
                    coreTempModel.append({'val':data.value, 'dataUnits':data.units, 'coreLabelStr':coreLabelStr});
                else
                    coreTempModel.set(dataName,{'val':data.value, 'dataUnits':data.units, 'coreLabelStr':coreLabelStr});

                return;
            }

            // memory
            if (sourceName.match("^mem/physical/free")) {
                delegate.memFree=data.value/1048576;
                delegate.memTotal=data.max/1048576;
                return;
            }
            if (sourceName.match("^mem/physical/used")) {
                delegate.memUsed=data.value/1048576;
                return;
            }
            if (sourceName.match("^mem/physical/buf")) {
                delegate.memBuffers=data.value/1048576;
                return;
            }
            if (sourceName.match("^mem/physical/cached")) {
                delegate.memCached=data.value/1048576;
                return;
            }
            if (sourceName.match("^mem/swap/used")) {
                delegate.swapUsed=data.value/1048576;
                delegate.swapTotal=data.max/1048576;
                return;
            }
            if (sourceName.match("^mem/swap/free")) {
                delegate.swapFree=data.value/1048576;
                return;
            }

            // uptime
            if (sourceName.match("^system/uptime")) {
                delegate.uptime = data.value;
                return;
            }
        }

        Component.onCompleted: {
            for (var i in systemInfoDataSource.sources)
                systemInfoDataSource.tryAddSource(systemInfoDataSource.sources[i]);
        }

        Component.onDestruction: {
            for (var i = connectedSources.length; i > 0; --i)
                disconnectSource(connectedSources[i - 1]);
        }
    }

    PlasmaCore.DataSource {
        id: nvidiaDataSource
        engine: 'executable'
        interval: if (showGpuTemp) updateInterval * 1000; else 0

        connectedSources: [ 'nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader' ]

        property bool gpuAppended: false

        onNewData: {
            var dataName = "NVIDIA";
            var gpuLabelStr = "NVIDIA GPU"
            var temperature = 0
            if (data['exit code'] != 0 || data.stdout == '') {
//                print('NVIDIA data error: ' + data.stderr)
                return
            } else {
                temperature = parseFloat(data.stdout)
                if (isNaN(temperature))
                    return
            }

            if (gpuAppended == false) {
                gpuTempModel.append({'val':temperature, 'dataUnits':'°C', 'gpuLabelStr':gpuLabelStr});
                gpuAppended = true
            } else {
                gpuTempModel.set(dataName,{'val':temperature, 'dataUnits':'°C', 'gpuLabelStr':gpuLabelStr});
            }
        }
    }

    PlasmaCore.DataSource {
        id: atiDataSource
        engine: 'executable'
        interval: if (showGpuTemp) updateInterval * 1000; else 0

        connectedSources: [ 'aticonfig --od-gettemperature | tail -1 | cut -c 43-44' ]

        property bool gpuAppended: false

        onNewData: {
            var dataName = "ATI";
            var gpuLabelStr = "ATI GPU"
            var temperature = 0
            if (data['exit code'] != 0 || data.stdout == '') {
//                print('ATI data error: ' + data.stderr)
                return
            } else {
                temperature = parseFloat(data.stdout)
                if (isNaN(temperature))
                    return
            }

            if (gpuAppended == false) {
                gpuTempModel.append({'val':temperature, 'dataUnits':'°C', 'gpuLabelStr':gpuLabelStr});
                gpuAppended = true
            } else {
                gpuTempModel.set(dataName,{'val':temperature, 'dataUnits':'°C', 'gpuLabelStr':gpuLabelStr});
            }
        }
    }

    PlasmaCore.DataSource {
        id: amdDataSource
        engine: 'executable'
        interval: if (showGpuTemp) updateInterval * 1000; else 0

        connectedSources: [ 'amdconfig --od-gettemperature | tail -1 | cut -c 43-44' ]

        property bool gpuAppended: false

        onNewData: {
            var dataName = "AMD";
            var gpuLabelStr = "AMD GPU"
            var temperature = 0
            if (data['exit code'] != 0 || data.stdout == '') {
//                print('AMD data error: ' + data.stderr)
                return
            } else {
                temperature = parseFloat(data.stdout)
                if (isNaN(temperature))
                    return
            }

            if (gpuAppended == false) {
                gpuTempModel.append({'val':temperature, 'dataUnits':'°C', 'gpuLabelStr':gpuLabelStr});
                gpuAppended = true
            } else {
                gpuTempModel.set(dataName,{'val':temperature, 'dataUnits':'°C', 'gpuLabelStr':gpuLabelStr});
            }
        }
    }

    PlasmaCore.DataSource {
        id: amdSensorsDataSource
        engine: "systemmonitor"
        interval: if (showGpuTemp) updateInterval * 1000; else 0

        property alias delegate: loader.item

        function tryAddSource(source) {
          if (connectedSources.indexOf(source) !== -1)
              return;
          // connect lm_sensors gpu temp source
          if (source.match("^lmsensors/amdgpu-pci-\\d+/edge")) {
              connectSource(source);
              return;
          }
        }

        onSourceAdded: tryAddSource(source)

        property bool gpuAppended: false

        onNewData: {
            if (data.value === undefined || delegate === undefined)
                return;

            var dataName = "AMD";
            var gpuLabelStr = "AMD GPU"

            if (gpuAppended == false) {
                gpuTempModel.append({'val':data.value, 'dataUnits':data.units, 'gpuLabelStr':gpuLabelStr});
                gpuAppended = true
            } else {
                gpuTempModel.set(dataName,{'val':data.value, 'dataUnits':data.units, 'gpuLabelStr':gpuLabelStr});
            }
        }
        Component.onCompleted: {
            for (var i in systemInfoDataSource.sources)
                systemInfoDataSource.tryAddSource(systemInfoDataSource.sources[i]);
        }

        Component.onDestruction: {
            for (var i = connectedSources.length; i > 0; --i)
                disconnectSource(connectedSources[i - 1]);
        }

    }

    Loader {
        id: loader
        anchors.fill: parent
        source: "skins/DefaultSkin.qml"
    }
}
