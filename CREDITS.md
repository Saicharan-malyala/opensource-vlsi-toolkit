# Credits and Acknowledgments

This repository contains **only our own installer scripts, automation utilities, and documentation**. No third-party code, binary, or design files are vendored or bundled into this repository.

All upstream tools, Process Design Kits (PDKs), and container images are cloned, downloaded, or installed at run-time directly from their respective official upstream maintainers. Licenses have **not** been independently verified; see upstream repositories for full terms and conditions.

---

## Upstream Frameworks and Projects

### 1. IIC-OSIC-TOOLS
- **Maintainer**: Institute for Integrated Circuits (IIC), Johannes Kepler University (JKU) Linz (Prof. Harald Pretl, Georg Zachl, et al.), forked and expanded from `efabless/foss-asic-tools`.
- **Repository**: [https://github.com/iic-jku/IIC-OSIC-TOOLS](https://github.com/iic-jku/IIC-OSIC-TOOLS)
- **Container Registry**: [https://hub.docker.com/r/hpretl/iic-osic-tools](https://hub.docker.com/r/hpretl/iic-osic-tools)
- **Upstream License**: Apache License 2.0 (see upstream repo)

### 2. LibreLane
- **Maintainer**: FOSSi Foundation (Free and Open Source Silicon Foundation)
- **Successor to**: OpenLane (v1 / v2)
- **Repository**: [https://github.com/librelane/librelane](https://github.com/librelane/librelane)
- **Documentation**: [https://librelane.readthedocs.io](https://librelane.readthedocs.io)
- **Upstream License**: Apache License 2.0

### 3. Ciel (PDK Package Manager)
- **Maintainer**: FOSSi Foundation (successor to Volare)
- **Repository**: [https://github.com/fossi-foundation/ciel](https://github.com/fossi-foundation/ciel)
- **Upstream License**: Apache License 2.0

### 4. The OpenROAD Project & OpenSTA
- **Maintainer**: The OpenROAD Project (Precision Innovations / UC San Diego / Siemens EDA)
- **Repository**: [https://github.com/The-OpenROAD-Project/OpenROAD](https://github.com/The-OpenROAD-Project/OpenROAD)
- **Prebuilt Binaries**: [https://openroad-flow-scripts.readthedocs.io](https://openroad-flow-scripts.readthedocs.io)
- **Upstream License**: BSD-3-Clause

### 5. SkyWater 130nm PDK (Sky130)
- **Maintainer**: SkyWater Technology and Google
- **Repository**: [https://github.com/google/skywater-pdk](https://github.com/google/skywater-pdk)
- **Upstream License**: Apache License 2.0

---

## Individual EDA Tools & Projects

| Tool | Primary Maintainer / Project | Official Website / Upstream Repo | License Link (See Upstream) |
| :--- | :--- | :--- | :--- |
| **Yosys** | YosysHQ GmbH (Claire Wolf et al.) | [https://github.com/YosysHQ/yosys](https://github.com/YosysHQ/yosys) | [ISC License](https://github.com/YosysHQ/yosys/blob/main/COPYING) |
| **Icarus Verilog** | Stephen Williams et al. | [https://github.com/steveicarus/iverilog](https://github.com/steveicarus/iverilog) | [GPL-2.0](https://github.com/steveicarus/iverilog/blob/master/COPYING) |
| **Verilator** | Wilson Snyder et al. | [https://verilator.org](https://verilator.org) | [LGPL-3.0 / Artistic-2.0](https://github.com/verilator/verilator/blob/master/LICENSE) |
| **GTKWave** | Tony Bybell / GTKWave Team | [https://gtkwave.sourceforge.net](https://gtkwave.sourceforge.net) | [GPL-2.0](https://github.com/gtkwave/gtkwave/blob/master/LICENSE) |
| **Magic VLSI** | Tim Edwards / Open Circuit Design | [http://opencircuitdesign.com/magic](http://opencircuitdesign.com/magic) | [BSD-like](http://opencircuitdesign.com/magic/license.html) |
| **Netgen** | Tim Edwards / Open Circuit Design | [http://opencircuitdesign.com/netgen](http://opencircuitdesign.com/netgen) | [GPL-1.0-or-later](http://opencircuitdesign.com/netgen/license.html) |
| **KLayout** | Matthias Köfferlein | [https://www.klayout.de](https://www.klayout.de) | [GPL-2.0](https://github.com/KLayout/klayout/blob/master/LICENSE) |
| **Xschem** | Stefan Schippers | [https://xschem.org](https://xschem.org) | [GPL-2.0](https://github.com/StefanSchippers/xschem/blob/master/LICENSE) |
| **ngspice** | ngspice development team | [https://ngspice.sourceforge.io](https://ngspice.sourceforge.io) | [BSD-3-Clause / LGPL](https://ngspice.sourceforge.io) |
| **cocotb** | cocotb contributors | [https://github.com/cocotb/cocotb](https://github.com/cocotb/cocotb) | [BSD-3-Clause](https://github.com/cocotb/cocotb/blob/master/LICENSE) |
| **pyuvm** | Ray Salemi et al. | [https://github.com/pyuvm/pyuvm](https://github.com/pyuvm/pyuvm) | [Apache-2.0](https://github.com/pyuvm/pyuvm/blob/master/LICENSE) |
| **GitHub CLI (`gh`)**| GitHub Inc. | [https://github.com/cli/cli](https://github.com/cli/cli) | [MIT License](https://github.com/cli/cli/blob/trunk/LICENSE) |
| **Docker** | Docker Inc. / Moby Project | [https://github.com/moby/moby](https://github.com/moby/moby) | [Apache-2.0](https://github.com/moby/moby/blob/master/LICENSE) |
| **Podman** | Red Hat / Containers Org | [https://github.com/containers/podman](https://github.com/containers/podman) | [Apache-2.0](https://github.com/containers/podman/blob/main/LICENSE) |
| **GNU Make** | Free Software Foundation | [https://www.gnu.org/software/make/](https://www.gnu.org/software/make/) | [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html) |
| **Git** | Software Freedom Conservancy | [https://git-scm.com](https://git-scm.com) | [GPL-2.0](https://git-scm.com) |

*Disclaimer: This repository is an independent installer and verification framework. It is not officially endorsed by or affiliated with Google, SkyWater, JKU, FOSSi Foundation, Precision Innovations, or Siemens EDA.*
