# typed: ignore
# lib/spoom/cli/bump.rb:7:0-198:3
module Spoom
end
# lib/spoom/cli/config.rb:7:0-52:3
module Spoom
end
# lib/spoom/cli/coverage.rb:7:0-222:3
module Spoom
end
# lib/spoom/cli/helper.rb:8:0-149:3
module Spoom
end
# lib/spoom/cli/lsp.rb:8:0-168:3
module Spoom
end
# lib/spoom/cli/run.rb:4:0-148:3
module Spoom
end
# lib/spoom/cli.rb:14:0-74:3
module Spoom
end
# lib/spoom/colors.rb:4:0-45:3
module Spoom
end
# lib/spoom/context/bundle.rb:4:0-67:3
module Spoom
end
# lib/spoom/context/exec.rb:4:0-50:3
module Spoom
end
# lib/spoom/context/file_system.rb:4:0-110:3
module Spoom
end
# lib/spoom/context/git.rb:4:0-137:3
module Spoom
end
# lib/spoom/context/sorbet.rb:4:0-171:3
module Spoom
end
# lib/spoom/context.rb:15:0-55:3
module Spoom
end
# lib/spoom/coverage/d3/base.rb:4:0-54:3
module Spoom
end
# lib/spoom/coverage/d3/circle_map.rb:6:0-184:3
module Spoom
end
# lib/spoom/coverage/d3/pie.rb:6:0-186:3
module Spoom
end
# lib/spoom/coverage/d3/timeline.rb:6:0-630:3
module Spoom
end
# lib/spoom/coverage/d3.rb:8:0-112:3
module Spoom
end
# lib/spoom/coverage/report.rb:8:0-331:3
module Spoom
end
# lib/spoom/coverage/snapshot.rb:4:0-165:3
module Spoom
end
# lib/spoom/coverage.rb:10:0-112:3
module Spoom
end
# lib/spoom/deadcode/definition.rb:4:0-98:3
module Spoom
end
# lib/spoom/deadcode/erb.rb:26:0-103:3
module Spoom
end
# lib/spoom/deadcode/index.rb:4:0-61:3
module Spoom
end
# lib/spoom/deadcode/indexer.rb:4:0-403:3
module Spoom
end
# lib/spoom/deadcode/plugins/base.rb:6:0-201:3
module Spoom
end
# lib/spoom/deadcode/plugins/ruby.rb:4:0-64:3
module Spoom
end
# lib/spoom/deadcode/reference.rb:4:0-34:3
module Spoom
end
# lib/spoom/deadcode/send.rb:4:0-18:3
module Spoom
end
# lib/spoom/deadcode.rb:16:0-55:3
module Spoom
end
# lib/spoom/file_collector.rb:4:0-102:3
module Spoom
end
# lib/spoom/file_tree.rb:4:0-283:3
module Spoom
end
# lib/spoom/location.rb:4:0-61:3
module Spoom
end
# lib/spoom/model/builder.rb:4:0-171:3
module Spoom
end
# lib/spoom/model/model.rb:4:0-365:3
module Spoom
end
# lib/spoom/model/printer.rb:4:0-117:3
module Spoom
end
# lib/spoom/model/visitor.rb:4:0-108:3
module Spoom
end
# lib/spoom/printer.rb:6:0-84:3
module Spoom
end
# lib/spoom/sorbet/config.rb:4:0-156:3
module Spoom
end
# lib/spoom/sorbet/errors.rb:4:0-175:3
module Spoom
end
# lib/spoom/sorbet/lsp/base.rb:4:0-75:3
module Spoom
end
# lib/spoom/sorbet/lsp/errors.rb:4:0-70:3
module Spoom
end
# lib/spoom/sorbet/lsp/structures.rb:7:0-366:3
module Spoom
end
# lib/spoom/sorbet/lsp.rb:11:0-238:3
module Spoom
end
# lib/spoom/sorbet/metrics.rb:6:0-35:3
module Spoom
end
# lib/spoom/sorbet/sigils.rb:7:0-91:3
module Spoom
end
# lib/spoom/sorbet.rb:12:0-44:3
module Spoom
end
# lib/spoom/timeline.rb:4:0-51:3
module Spoom
end
# lib/spoom/version.rb:4:0-6:3
module Spoom
end
# lib/spoom.rb:7:0-13:3
module Spoom
end
# lib/spoom/cli/bump.rb:8:2-197:5
module Spoom::Cli
end
# lib/spoom/cli/config.rb:8:2-51:5
module Spoom::Cli
end
# lib/spoom/cli/coverage.rb:8:2-221:5
module Spoom::Cli
end
# lib/spoom/cli/helper.rb:9:2-148:5
module Spoom::Cli
end
# lib/spoom/cli/lsp.rb:9:2-167:5
module Spoom::Cli
end
# lib/spoom/cli/run.rb:5:2-147:5
module Spoom::Cli
end
# lib/spoom/cli.rb:15:2-73:5
module Spoom::Cli
end
# lib/spoom/cli/bump.rb:9:4-196:7
class Spoom::Cli::Bump < Ref[Thor]
  # lib/spoom/cli/bump.rb:49:6-167:9
  def bump; end
  # lib/spoom/cli/bump.rb:170:8-190:11
  def print_changes; end
  # lib/spoom/cli/bump.rb:192:8-194:11
  def undo_changes; end
end
# lib/spoom/cli/config.rb:9:4-50:7
class Spoom::Cli::Config < Ref[Thor]
  # lib/spoom/cli/config.rb:15:6-49:9
  def show; end
end
# lib/spoom/cli/coverage.rb:9:4-220:7
class Spoom::Cli::Coverage < Ref[Thor]
  # lib/spoom/cli/coverage.rb:20:6-34:9
  def snapshot; end
  # lib/spoom/cli/coverage.rb:42:6-113:9
  def timeline; end
  # lib/spoom/cli/coverage.rb:142:6-170:9
  def report; end
  # lib/spoom/cli/coverage.rb:173:6-186:9
  def open; end
  # lib/spoom/cli/coverage.rb:189:8-196:11
  def parse_time; end
  # lib/spoom/cli/coverage.rb:198:8-208:11
  def bundle_install; end
  # lib/spoom/cli/coverage.rb:210:8-218:11
  def message_no_data; end
end
# lib/spoom/cli/helper.rb:10:4-147:7
module Spoom::Cli::Helper
  # lib/spoom/cli/helper.rb:20:6-27:9
  def say; end
  # lib/spoom/cli/helper.rb:39:6-47:9
  def say_error; end
  # lib/spoom/cli/helper.rb:51:6-53:9
  def context; end
  # lib/spoom/cli/helper.rb:57:6-68:9
  def context_requiring_sorbet!; end
  # lib/spoom/cli/helper.rb:72:6-74:9
  def exec_path; end
  # lib/spoom/cli/helper.rb:83:6-85:9
  def color?; end
  # lib/spoom/cli/helper.rb:88:6-108:9
  def highlight; end
  # lib/spoom/cli/helper.rb:112:6-116:9
  def colorize; end
  # lib/spoom/cli/helper.rb:119:6-121:9
  def blue; end
  # lib/spoom/cli/helper.rb:124:6-126:9
  def cyan; end
  # lib/spoom/cli/helper.rb:129:6-131:9
  def gray; end
  # lib/spoom/cli/helper.rb:134:6-136:9
  def green; end
  # lib/spoom/cli/helper.rb:139:6-141:9
  def red; end
  # lib/spoom/cli/helper.rb:144:6-146:9
  def yellow; end
end
# lib/spoom/cli/lsp.rb:10:4-166:7
class Spoom::Cli::LSP < Ref[Thor]
  # lib/spoom/cli/lsp.rb:16:6-22:9
  def show; end
  # lib/spoom/cli/lsp.rb:26:6-37:9
  def list; end
  # lib/spoom/cli/lsp.rb:41:6-51:9
  def hover; end
  # lib/spoom/cli/lsp.rb:55:6-61:9
  def defs; end
  # lib/spoom/cli/lsp.rb:65:6-71:9
  def find; end
  # lib/spoom/cli/lsp.rb:75:6-81:9
  def symbols; end
  # lib/spoom/cli/lsp.rb:85:6-91:9
  def refs; end
  # lib/spoom/cli/lsp.rb:95:6-101:9
  def sigs; end
  # lib/spoom/cli/lsp.rb:105:6-111:9
  def types; end
  # lib/spoom/cli/lsp.rb:114:8-127:11
  def lsp_client; end
  # lib/spoom/cli/lsp.rb:129:8-135:11
  def symbol_printer; end
  # lib/spoom/cli/lsp.rb:137:8-160:11
  def run; end
  # lib/spoom/cli/lsp.rb:162:8-164:11
  def to_uri; end
end
# lib/spoom/cli.rb:16:4-72:7
class Spoom::Cli::Main < Ref[Thor]
  # lib/spoom/cli.rb:43:6-58:9
  def files; end
  # lib/spoom/cli.rb:61:6-63:9
  def __print_version; end
  # lib/spoom/cli.rb:68:8-70:11
  def exit_on_failure?; end
end
# lib/spoom/cli/run.rb:6:4-146:7
class Spoom::Cli::Run < Ref[Thor]
  # lib/spoom/cli/run.rb:26:6-119:9
  def tc; end
  # lib/spoom/cli/run.rb:122:8-129:11
  def format_error; end
  # lib/spoom/cli/run.rb:131:8-144:11
  def colorize_message; end
end
# lib/spoom/colors.rb:5:2-35:5
class Spoom::Color < Ref[T::Enum]
  # lib/spoom/colors.rb:32:4-34:7
  def ansi_code; end
end
# lib/spoom/colors.rb:37:2-44:5
module Spoom::Colorize
  # lib/spoom/colors.rb:41:4-43:7
  def set_color; end
end
# lib/spoom/context/bundle.rb:5:2-66:5
class Spoom::Context
end
# lib/spoom/context/exec.rb:25:2-49:5
class Spoom::Context
end
# lib/spoom/context/file_system.rb:5:2-109:5
class Spoom::Context
end
# lib/spoom/context/git.rb:33:2-136:5
class Spoom::Context
end
# lib/spoom/context/sorbet.rb:5:2-170:5
class Spoom::Context
end
# lib/spoom/context.rb:20:2-54:5
class Spoom::Context
  # lib/spoom/context.rb:44:16-44:30
  attr_reader :absolute_path
  # lib/spoom/context.rb:37:6-39:9
  def mktmp!; end
  # lib/spoom/context.rb:51:4-53:7
  def initialize; end
end
# lib/spoom/context/bundle.rb:7:4-65:7
module Spoom::Context::Bundle
  # lib/spoom/context/bundle.rb:15:6-17:9
  def read_gemfile; end
  # lib/spoom/context/bundle.rb:21:6-23:9
  def read_gemfile_lock; end
  # lib/spoom/context/bundle.rb:27:6-29:9
  def write_gemfile!; end
  # lib/spoom/context/bundle.rb:33:6-36:9
  def bundle; end
  # lib/spoom/context/bundle.rb:40:6-42:9
  def bundle_install!; end
  # lib/spoom/context/bundle.rb:46:6-48:9
  def bundle_exec; end
  # lib/spoom/context/bundle.rb:51:6-56:9
  def gemfile_lock_specs; end
  # lib/spoom/context/bundle.rb:62:6-64:9
  def gem_version_from_gemfile_lock; end
end
# lib/spoom/context/exec.rb:27:4-48:7
module Spoom::Context::Exec
  # lib/spoom/context/exec.rb:35:6-47:9
  def exec; end
end
# lib/spoom/context/file_system.rb:7:4-108:7
module Spoom::Context::FileSystem
  # lib/spoom/context/file_system.rb:15:6-17:9
  def absolute_path_to; end
  # lib/spoom/context/file_system.rb:21:6-23:9
  def exist?; end
  # lib/spoom/context/file_system.rb:27:6-30:9
  def mkdir!; end
  # lib/spoom/context/file_system.rb:34:6-38:9
  def glob; end
  # lib/spoom/context/file_system.rb:42:6-44:9
  def list; end
  # lib/spoom/context/file_system.rb:53:6-61:9
  def collect_files; end
  # lib/spoom/context/file_system.rb:65:6-67:9
  def file?; end
  # lib/spoom/context/file_system.rb:73:6-75:9
  def read; end
  # lib/spoom/context/file_system.rb:81:6-85:9
  def write!; end
  # lib/spoom/context/file_system.rb:89:6-91:9
  def remove!; end
  # lib/spoom/context/file_system.rb:95:6-99:9
  def move!; end
  # lib/spoom/context/file_system.rb:105:6-107:9
  def destroy!; end
end
# lib/spoom/context/git.rb:35:4-135:7
module Spoom::Context::Git
  # lib/spoom/context/git.rb:43:6-45:9
  def git; end
  # lib/spoom/context/git.rb:52:6-58:9
  def git_init!; end
  # lib/spoom/context/git.rb:62:6-64:9
  def git_checkout!; end
  # lib/spoom/context/git.rb:68:6-74:9
  def git_checkout_new_branch!; end
  # lib/spoom/context/git.rb:78:6-85:9
  def git_commit!; end
  # lib/spoom/context/git.rb:89:6-94:9
  def git_current_branch; end
  # lib/spoom/context/git.rb:98:6-100:9
  def git_diff; end
  # lib/spoom/context/git.rb:104:6-112:9
  def git_last_commit; end
  # lib/spoom/context/git.rb:115:6-117:9
  def git_log; end
  # lib/spoom/context/git.rb:121:6-123:9
  def git_push!; end
  # lib/spoom/context/git.rb:126:6-128:9
  def git_show; end
  # lib/spoom/context/git.rb:132:6-134:9
  def git_workdir_clean?; end
end
# lib/spoom/context/sorbet.rb:7:4-169:7
module Spoom::Context::Sorbet
  # lib/spoom/context/sorbet.rb:15:6-30:9
  def srb; end
  # lib/spoom/context/sorbet.rb:33:6-36:9
  def srb_tc; end
  # lib/spoom/context/sorbet.rb:45:6-61:9
  def srb_metrics; end
  # lib/spoom/context/sorbet.rb:65:6-94:9
  def srb_files; end
  # lib/spoom/context/sorbet.rb:104:6-107:9
  def srb_files_with_strictness; end
  # lib/spoom/context/sorbet.rb:110:6-115:9
  def srb_version; end
  # lib/spoom/context/sorbet.rb:119:6-121:9
  def has_sorbet_config?; end
  # lib/spoom/context/sorbet.rb:124:6-126:9
  def sorbet_config; end
  # lib/spoom/context/sorbet.rb:130:6-132:9
  def read_sorbet_config; end
  # lib/spoom/context/sorbet.rb:136:6-138:9
  def write_sorbet_config!; end
  # lib/spoom/context/sorbet.rb:142:6-144:9
  def read_file_strictness; end
  # lib/spoom/context/sorbet.rb:148:6-156:9
  def sorbet_intro_commit; end
  # lib/spoom/context/sorbet.rb:160:6-168:9
  def sorbet_removal_commit; end
end
# lib/spoom/coverage/d3/base.rb:5:2-53:5
module Spoom::Coverage
end
# lib/spoom/coverage/d3/circle_map.rb:7:2-183:5
module Spoom::Coverage
end
# lib/spoom/coverage/d3/pie.rb:7:2-185:5
module Spoom::Coverage
end
# lib/spoom/coverage/d3/timeline.rb:7:2-629:5
module Spoom::Coverage
end
# lib/spoom/coverage/d3.rb:9:2-111:5
module Spoom::Coverage
end
# lib/spoom/coverage/report.rb:9:2-330:5
module Spoom::Coverage
end
# lib/spoom/coverage/snapshot.rb:5:2-164:5
module Spoom::Coverage
end
# lib/spoom/coverage.rb:11:2-111:5
module Spoom::Coverage
  # lib/spoom/coverage.rb:16:6-80:9
  def snapshot; end
  # lib/spoom/coverage.rb:83:6-100:9
  def report; end
  # lib/spoom/coverage.rb:103:6-109:9
  def file_tree; end
end
# lib/spoom/coverage/report.rb:88:4-259:7
module Spoom::Coverage::Cards
end
# lib/spoom/coverage/report.rb:89:6-103:9
class Spoom::Coverage::Cards::Card < Spoom::Coverage::Template
  # lib/spoom/coverage/report.rb:95:20-95:26
  attr_reader :title
  # lib/spoom/coverage/report.rb:95:28-95:33
  attr_reader :body
  # lib/spoom/coverage/report.rb:98:8-102:11
  def initialize; end
end
# lib/spoom/coverage/report.rb:105:6-121:9
class Spoom::Coverage::Cards::Erb < Spoom::Coverage::Cards::Card
  # lib/spoom/coverage/report.rb:112:8-112:27
  def initialize; end
  # lib/spoom/coverage/report.rb:115:8-117:11
  def html; end
  # lib/spoom/coverage/report.rb:120:8-120:20
  def erb; end
end
# lib/spoom/coverage/report.rb:153:6-175:9
class Spoom::Coverage::Cards::Map < Spoom::Coverage::Cards::Card
  # lib/spoom/coverage/report.rb:164:8-174:11
  def initialize; end
end
# lib/spoom/coverage/report.rb:123:6-151:9
class Spoom::Coverage::Cards::Snapshot < Spoom::Coverage::Cards::Card
  # lib/spoom/coverage/report.rb:129:20-129:29
  attr_reader :snapshot
  # lib/spoom/coverage/report.rb:132:8-135:11
  def initialize; end
  # lib/spoom/coverage/report.rb:138:8-140:11
  def pie_sigils; end
  # lib/spoom/coverage/report.rb:143:8-145:11
  def pie_calls; end
  # lib/spoom/coverage/report.rb:148:8-150:11
  def pie_sigs; end
end
# lib/spoom/coverage/report.rb:240:6-258:9
class Spoom::Coverage::Cards::SorbetIntro < Spoom::Coverage::Cards::Erb
  # lib/spoom/coverage/report.rb:244:8-247:11
  def initialize; end
  # lib/spoom/coverage/report.rb:250:8-257:11
  def erb; end
end
# lib/spoom/coverage/report.rb:177:6-238:9
class Spoom::Coverage::Cards::Timeline < Spoom::Coverage::Cards::Card
  # lib/spoom/coverage/report.rb:181:8-183:11
  def initialize; end
end
# lib/spoom/coverage/report.rb:194:8-201:11
class Spoom::Coverage::Cards::Timeline::Calls < Spoom::Coverage::Cards::Timeline
  # lib/spoom/coverage/report.rb:198:10-200:13
  def initialize; end
end
# lib/spoom/coverage/report.rb:212:8-219:11
class Spoom::Coverage::Cards::Timeline::RBIs < Spoom::Coverage::Cards::Timeline
  # lib/spoom/coverage/report.rb:216:10-218:13
  def initialize; end
end
# lib/spoom/coverage/report.rb:230:8-237:11
class Spoom::Coverage::Cards::Timeline::Runtimes < Spoom::Coverage::Cards::Timeline
  # lib/spoom/coverage/report.rb:234:10-236:13
  def initialize; end
end
# lib/spoom/coverage/report.rb:185:8-192:11
class Spoom::Coverage::Cards::Timeline::Sigils < Spoom::Coverage::Cards::Timeline
  # lib/spoom/coverage/report.rb:189:10-191:13
  def initialize; end
end
# lib/spoom/coverage/report.rb:203:8-210:11
class Spoom::Coverage::Cards::Timeline::Sigs < Spoom::Coverage::Cards::Timeline
  # lib/spoom/coverage/report.rb:207:10-209:13
  def initialize; end
end
# lib/spoom/coverage/report.rb:221:8-228:11
class Spoom::Coverage::Cards::Timeline::Versions < Spoom::Coverage::Cards::Timeline
  # lib/spoom/coverage/report.rb:225:10-227:13
  def initialize; end
end
# lib/spoom/coverage/d3/base.rb:6:4-52:7
module Spoom::Coverage::D3
end
# lib/spoom/coverage/d3/circle_map.rb:8:4-182:7
module Spoom::Coverage::D3
end
# lib/spoom/coverage/d3/pie.rb:8:4-184:7
module Spoom::Coverage::D3
end
# lib/spoom/coverage/d3/timeline.rb:8:4-628:7
module Spoom::Coverage::D3
end
# lib/spoom/coverage/d3.rb:10:4-110:7
module Spoom::Coverage::D3
  # lib/spoom/coverage/d3.rb:21:8-58:11
  def header_style; end
  # lib/spoom/coverage/d3.rb:61:8-100:11
  def header_script; end
end
# lib/spoom/coverage/d3/base.rb:7:6-51:9
class Spoom::Coverage::D3::Base
  # lib/spoom/coverage/d3/base.rb:14:20-14:23
  attr_reader :id
  # lib/spoom/coverage/d3/base.rb:17:8-20:11
  def initialize; end
  # lib/spoom/coverage/d3/base.rb:26:10-28:13
  def header_style; end
  # lib/spoom/coverage/d3/base.rb:31:10-33:13
  def header_script; end
  # lib/spoom/coverage/d3/base.rb:37:8-42:11
  def html; end
  # lib/spoom/coverage/d3/base.rb:45:8-47:11
  def tooltip; end
  # lib/spoom/coverage/d3/base.rb:50:8-50:23
  def script; end
end
# lib/spoom/coverage/d3/circle_map.rb:9:6-181:9
class Spoom::Coverage::D3::CircleMap < Spoom::Coverage::D3::Base
  # lib/spoom/coverage/d3/circle_map.rb:14:10-37:13
  def header_style; end
  # lib/spoom/coverage/d3/circle_map.rb:40:10-55:13
  def header_script; end
  # lib/spoom/coverage/d3/circle_map.rb:59:8-146:11
  def script; end
end
# lib/spoom/coverage/d3/circle_map.rb:148:8-180:11
class Spoom::Coverage::D3::CircleMap::Sigils < Spoom::Coverage::D3::CircleMap
  # lib/spoom/coverage/d3/circle_map.rb:159:10-163:13
  def initialize; end
  # lib/spoom/coverage/d3/circle_map.rb:166:10-179:13
  def tree_node_to_json; end
end
# lib/spoom/coverage/d3.rb:103:6-109:9
class Spoom::Coverage::D3::ColorPalette < Ref[T::Struct]
  # lib/spoom/coverage/d3.rb:104:8-104:28
  prop :ignore, type: String
  # lib/spoom/coverage/d3.rb:105:8-105:27
  prop :false, type: String
  # lib/spoom/coverage/d3.rb:106:8-106:26
  prop :true, type: String
  # lib/spoom/coverage/d3.rb:107:8-107:28
  prop :strict, type: String
  # lib/spoom/coverage/d3.rb:108:8-108:28
  prop :strong, type: String
end
# lib/spoom/coverage/d3/pie.rb:9:6-183:9
class Spoom::Coverage::D3::Pie < Spoom::Coverage::D3::Base
  # lib/spoom/coverage/d3/pie.rb:16:8-19:11
  def initialize; end
  # lib/spoom/coverage/d3/pie.rb:25:10-40:13
  def header_style; end
  # lib/spoom/coverage/d3/pie.rb:43:10-52:13
  def header_script; end
  # lib/spoom/coverage/d3/pie.rb:56:8-121:11
  def script; end
end
# lib/spoom/coverage/d3/pie.rb:141:8-157:11
class Spoom::Coverage::D3::Pie::Calls < Spoom::Coverage::D3::Pie
  # lib/spoom/coverage/d3/pie.rb:145:10-147:13
  def initialize; end
  # lib/spoom/coverage/d3/pie.rb:150:10-156:13
  def tooltip; end
end
# lib/spoom/coverage/d3/pie.rb:123:8-139:11
class Spoom::Coverage::D3::Pie::Sigils < Spoom::Coverage::D3::Pie
  # lib/spoom/coverage/d3/pie.rb:127:10-129:13
  def initialize; end
  # lib/spoom/coverage/d3/pie.rb:132:10-138:13
  def tooltip; end
end
# lib/spoom/coverage/d3/pie.rb:159:8-182:11
class Spoom::Coverage::D3::Pie::Sigs < Spoom::Coverage::D3::Pie
  # lib/spoom/coverage/d3/pie.rb:163:10-169:13
  def initialize; end
  # lib/spoom/coverage/d3/pie.rb:172:10-181:13
  def tooltip; end
end
# lib/spoom/coverage/d3/timeline.rb:9:6-627:9
class Spoom::Coverage::D3::Timeline < Spoom::Coverage::D3::Base
  # lib/spoom/coverage/d3/timeline.rb:16:8-19:11
  def initialize; end
  # lib/spoom/coverage/d3/timeline.rb:25:10-76:13
  def header_style; end
  # lib/spoom/coverage/d3/timeline.rb:79:10-97:13
  def header_script; end
  # lib/spoom/coverage/d3/timeline.rb:101:8-123:11
  def script; end
  # lib/spoom/coverage/d3/timeline.rb:126:8-126:21
  def plot; end
  # lib/spoom/coverage/d3/timeline.rb:129:8-142:11
  def x_scale; end
  # lib/spoom/coverage/d3/timeline.rb:145:8-155:11
  def x_ticks; end
  # lib/spoom/coverage/d3/timeline.rb:158:8-171:11
  def y_scale; end
  # lib/spoom/coverage/d3/timeline.rb:174:8-184:11
  def y_ticks; end
  # lib/spoom/coverage/d3/timeline.rb:187:8-200:11
  def area; end
  # lib/spoom/coverage/d3/timeline.rb:203:8-214:11
  def line; end
  # lib/spoom/coverage/d3/timeline.rb:217:8-230:11
  def points; end
end
# lib/spoom/coverage/d3/timeline.rb:448:8-473:11
class Spoom::Coverage::D3::Timeline::Calls < Spoom::Coverage::D3::Timeline::Stacked
  # lib/spoom/coverage/d3/timeline.rb:452:10-463:13
  def initialize; end
  # lib/spoom/coverage/d3/timeline.rb:466:10-472:13
  def tooltip; end
end
# lib/spoom/coverage/d3/timeline.rb:505:8-626:11
class Spoom::Coverage::D3::Timeline::RBIs < Spoom::Coverage::D3::Timeline::Stacked
  # lib/spoom/coverage/d3/timeline.rb:509:10-520:13
  def initialize; end
  # lib/spoom/coverage/d3/timeline.rb:523:10-534:13
  def tooltip; end
  # lib/spoom/coverage/d3/timeline.rb:537:10-574:13
  def script; end
  # lib/spoom/coverage/d3/timeline.rb:577:10-614:13
  def line; end
  # lib/spoom/coverage/d3/timeline.rb:617:10-625:13
  def plot; end
end
# lib/spoom/coverage/d3/timeline.rb:282:8-327:11
class Spoom::Coverage::D3::Timeline::Runtimes < Spoom::Coverage::D3::Timeline
  # lib/spoom/coverage/d3/timeline.rb:286:10-295:13
  def initialize; end
  # lib/spoom/coverage/d3/timeline.rb:298:10-308:13
  def tooltip; end
  # lib/spoom/coverage/d3/timeline.rb:311:10-326:13
  def plot; end
end
# lib/spoom/coverage/d3/timeline.rb:421:8-446:11
class Spoom::Coverage::D3::Timeline::Sigils < Spoom::Coverage::D3::Timeline::Stacked
  # lib/spoom/coverage/d3/timeline.rb:425:10-436:13
  def initialize; end
  # lib/spoom/coverage/d3/timeline.rb:439:10-445:13
  def tooltip; end
end
# lib/spoom/coverage/d3/timeline.rb:475:8-503:11
class Spoom::Coverage::D3::Timeline::Sigs < Spoom::Coverage::D3::Timeline::Stacked
  # lib/spoom/coverage/d3/timeline.rb:479:10-493:13
  def initialize; end
  # lib/spoom/coverage/d3/timeline.rb:496:10-502:13
  def tooltip; end
end
# lib/spoom/coverage/d3/timeline.rb:329:8-419:11
class Spoom::Coverage::D3::Timeline::Stacked < Spoom::Coverage::D3::Timeline
  # lib/spoom/coverage/d3/timeline.rb:336:10-374:13
  def script; end
  # lib/spoom/coverage/d3/timeline.rb:377:10-385:13
  def plot; end
  # lib/spoom/coverage/d3/timeline.rb:388:10-418:13
  def line; end
end
# lib/spoom/coverage/d3/timeline.rb:232:8-280:11
class Spoom::Coverage::D3::Timeline::Versions < Spoom::Coverage::D3::Timeline
  # lib/spoom/coverage/d3/timeline.rb:236:10-246:13
  def initialize; end
  # lib/spoom/coverage/d3/timeline.rb:249:10-260:13
  def tooltip; end
  # lib/spoom/coverage/d3/timeline.rb:263:10-279:13
  def plot; end
end
# lib/spoom/coverage/report.rb:38:4-86:7
class Spoom::Coverage::Page < Spoom::Coverage::Template
  # lib/spoom/coverage/report.rb:47:18-47:24
  attr_reader :title
  # lib/spoom/coverage/report.rb:50:18-50:26
  attr_reader :palette
  # lib/spoom/coverage/report.rb:53:6-57:9
  def initialize; end
  # lib/spoom/coverage/report.rb:60:6-62:9
  def header_style; end
  # lib/spoom/coverage/report.rb:65:6-67:9
  def header_script; end
  # lib/spoom/coverage/report.rb:70:6-72:9
  def header_html; end
  # lib/spoom/coverage/report.rb:75:6-77:9
  def body_html; end
  # lib/spoom/coverage/report.rb:80:6-80:20
  def cards; end
  # lib/spoom/coverage/report.rb:83:6-85:9
  def footer_html; end
end
# lib/spoom/coverage/report.rb:261:4-329:7
class Spoom::Coverage::Report < Spoom::Coverage::Page
  # lib/spoom/coverage/report.rb:276:6-294:9
  def initialize; end
  # lib/spoom/coverage/report.rb:297:6-305:9
  def header_html; end
  # lib/spoom/coverage/report.rb:308:6-328:9
  def cards; end
end
# lib/spoom/coverage/snapshot.rb:6:4-93:7
class Spoom::Coverage::Snapshot < Ref[T::Struct]
  # lib/spoom/coverage/snapshot.rb:33:6-36:9
  def print; end
  # lib/spoom/coverage/snapshot.rb:39:6-41:9
  def to_json; end
  # lib/spoom/coverage/snapshot.rb:47:8-49:11
  def from_json; end
  # lib/spoom/coverage/snapshot.rb:52:8-91:11
  def from_obj; end
  # lib/spoom/coverage/snapshot.rb:9:6-9:61
  prop :timestamp, type: Integer
  # lib/spoom/coverage/snapshot.rb:10:6-10:59
  prop :version_static, type: T.nilable(String)
  # lib/spoom/coverage/snapshot.rb:11:6-11:60
  prop :version_runtime, type: T.nilable(String)
  # lib/spoom/coverage/snapshot.rb:12:6-12:41
  prop :duration, type: Integer
  # lib/spoom/coverage/snapshot.rb:13:6-13:55
  prop :commit_sha, type: T.nilable(String)
  # lib/spoom/coverage/snapshot.rb:14:6-14:62
  prop :commit_timestamp, type: T.nilable(Integer)
  # lib/spoom/coverage/snapshot.rb:15:6-15:38
  prop :files, type: Integer
  # lib/spoom/coverage/snapshot.rb:16:6-16:42
  prop :rbi_files, type: Integer
  # lib/spoom/coverage/snapshot.rb:17:6-17:40
  prop :modules, type: Integer
  # lib/spoom/coverage/snapshot.rb:18:6-18:40
  prop :classes, type: Integer
  # lib/spoom/coverage/snapshot.rb:19:6-19:50
  prop :singleton_classes, type: Integer
  # lib/spoom/coverage/snapshot.rb:20:6-20:52
  prop :methods_without_sig, type: Integer
  # lib/spoom/coverage/snapshot.rb:21:6-21:49
  prop :methods_with_sig, type: Integer
  # lib/spoom/coverage/snapshot.rb:22:6-22:46
  prop :calls_untyped, type: Integer
  # lib/spoom/coverage/snapshot.rb:23:6-23:44
  prop :calls_typed, type: Integer
  # lib/spoom/coverage/snapshot.rb:24:6-24:66
  prop :sigils, type: T::Hash[String, Integer]
  # lib/spoom/coverage/snapshot.rb:25:6-25:64
  prop :methods_with_sig_excluding_rbis, type: Integer
  # lib/spoom/coverage/snapshot.rb:26:6-26:67
  prop :methods_without_sig_excluding_rbis, type: Integer
  # lib/spoom/coverage/snapshot.rb:27:6-27:81
  prop :sigils_excluding_rbis, type: T::Hash[String, Integer]
end
# lib/spoom/coverage/snapshot.rb:95:4-163:7
class Spoom::Coverage::SnapshotPrinter < Spoom::Printer
  # lib/spoom/coverage/snapshot.rb:99:6-142:9
  def print_snapshot; end
  # lib/spoom/coverage/snapshot.rb:147:6-155:9
  def print_map; end
  # lib/spoom/coverage/snapshot.rb:158:6-162:9
  def percent; end
end
# lib/spoom/coverage/report.rb:10:4-36:7
class Spoom::Coverage::Template
  # lib/spoom/coverage/report.rb:18:6-20:9
  def initialize; end
  # lib/spoom/coverage/report.rb:23:6-25:9
  def erb; end
  # lib/spoom/coverage/report.rb:28:6-30:9
  def html; end
  # lib/spoom/coverage/report.rb:33:6-35:9
  def get_binding; end
end
# lib/spoom/deadcode/definition.rb:5:2-97:5
module Spoom::Deadcode
end
# lib/spoom/deadcode/erb.rb:27:2-102:5
module Spoom::Deadcode
end
# lib/spoom/deadcode/index.rb:5:2-60:5
module Spoom::Deadcode
end
# lib/spoom/deadcode/indexer.rb:5:2-402:5
module Spoom::Deadcode
end
# lib/spoom/deadcode/plugins/base.rb:7:2-200:5
module Spoom::Deadcode
end
# lib/spoom/deadcode/plugins/ruby.rb:5:2-63:5
module Spoom::Deadcode
end
# lib/spoom/deadcode/reference.rb:5:2-33:5
module Spoom::Deadcode
end
# lib/spoom/deadcode/send.rb:5:2-17:5
module Spoom::Deadcode
end
# lib/spoom/deadcode.rb:17:2-54:5
module Spoom::Deadcode
  # lib/spoom/deadcode.rb:38:6-46:9
  def index_ruby; end
  # lib/spoom/deadcode.rb:49:6-52:9
  def index_erb; end
end
# lib/spoom/deadcode/definition.rb:7:4-96:7
class Spoom::Deadcode::Definition < Ref[T::Struct]
  # lib/spoom/deadcode/definition.rb:41:6-43:9
  def attr_reader?; end
  # lib/spoom/deadcode/definition.rb:46:6-48:9
  def attr_writer?; end
  # lib/spoom/deadcode/definition.rb:51:6-53:9
  def class?; end
  # lib/spoom/deadcode/definition.rb:56:6-58:9
  def constant?; end
  # lib/spoom/deadcode/definition.rb:61:6-63:9
  def method?; end
  # lib/spoom/deadcode/definition.rb:66:6-68:9
  def module?; end
  # lib/spoom/deadcode/definition.rb:73:6-75:9
  def alive?; end
  # lib/spoom/deadcode/definition.rb:78:6-80:9
  def alive!; end
  # lib/spoom/deadcode/definition.rb:83:6-85:9
  def dead?; end
  # lib/spoom/deadcode/definition.rb:88:6-90:9
  def ignored?; end
  # lib/spoom/deadcode/definition.rb:93:6-95:9
  def ignored!; end
  # lib/spoom/deadcode/definition.rb:32:6-32:23
  const :kind, type: Kind
  # lib/spoom/deadcode/definition.rb:33:6-33:25
  const :name, type: String
  # lib/spoom/deadcode/definition.rb:34:6-34:30
  const :full_name, type: String
  # lib/spoom/deadcode/definition.rb:35:6-35:31
  const :location, type: Location
  # lib/spoom/deadcode/definition.rb:36:6-36:50
  const :status, type: Status
end
# lib/spoom/deadcode/definition.rb:10:6-19:9
class Spoom::Deadcode::Definition::Kind < Ref[T::Enum]
end
# lib/spoom/deadcode/definition.rb:21:6-30:9
class Spoom::Deadcode::Definition::Status < Ref[T::Enum]
end
# lib/spoom/deadcode/erb.rb:29:4-101:7
class Spoom::Deadcode::ERB < Ref[::Erubi::Engine]
  # lib/spoom/deadcode/erb.rb:33:6-43:9
  def initialize; end
  # lib/spoom/deadcode/erb.rb:48:6-61:9
  def add_text; end
  # lib/spoom/deadcode/erb.rb:66:6-80:9
  def add_expression; end
  # lib/spoom/deadcode/erb.rb:83:6-86:9
  def add_code; end
  # lib/spoom/deadcode/erb.rb:89:6-92:9
  def add_postamble; end
  # lib/spoom/deadcode/erb.rb:95:6-100:9
  def flush_newline_if_pending; end
end
# lib/spoom/deadcode.rb:18:4-29:7
class Spoom::Deadcode::Error < Spoom::Error
  # lib/spoom/deadcode.rb:25:6-28:9
  def initialize; end
end
# lib/spoom/deadcode/index.rb:6:4-59:7
class Spoom::Deadcode::Index
  # lib/spoom/deadcode/index.rb:10:18-10:30
  attr_reader :definitions
  # lib/spoom/deadcode/index.rb:13:18-13:29
  attr_reader :references
  # lib/spoom/deadcode/index.rb:16:6-19:9
  def initialize; end
  # lib/spoom/deadcode/index.rb:24:6-26:9
  def define; end
  # lib/spoom/deadcode/index.rb:29:6-31:9
  def reference; end
  # lib/spoom/deadcode/index.rb:37:6-41:9
  def finalize!; end
  # lib/spoom/deadcode/index.rb:46:6-48:9
  def definitions_for_name; end
  # lib/spoom/deadcode/index.rb:51:6-53:9
  def all_definitions; end
  # lib/spoom/deadcode/index.rb:56:6-58:9
  def all_references; end
end
# lib/spoom/deadcode/indexer.rb:6:4-401:7
class Spoom::Deadcode::Indexer < Ref[SyntaxTree::Visitor]
  # lib/spoom/deadcode/indexer.rb:10:18-10:23
  attr_reader :path
  # lib/spoom/deadcode/indexer.rb:10:25-10:35
  attr_reader :file_name
  # lib/spoom/deadcode/indexer.rb:13:18-13:24
  attr_reader :index
  # lib/spoom/deadcode/indexer.rb:16:6-30:9
  def initialize; end
  # lib/spoom/deadcode/indexer.rb:35:6-42:9
  def visit; end
  # lib/spoom/deadcode/indexer.rb:45:6-47:9
  def visit_alias; end
  # lib/spoom/deadcode/indexer.rb:50:6-54:9
  def visit_aref; end
  # lib/spoom/deadcode/indexer.rb:57:6-61:9
  def visit_aref_field; end
  # lib/spoom/deadcode/indexer.rb:64:6-75:9
  def visit_arg_block; end
  # lib/spoom/deadcode/indexer.rb:78:6-91:9
  def visit_binary; end
  # lib/spoom/deadcode/indexer.rb:94:6-103:9
  def visit_call; end
  # lib/spoom/deadcode/indexer.rb:106:6-116:9
  def visit_class; end
  # lib/spoom/deadcode/indexer.rb:119:6-128:9
  def visit_command; end
  # lib/spoom/deadcode/indexer.rb:131:6-141:9
  def visit_command_call; end
  # lib/spoom/deadcode/indexer.rb:144:6-146:9
  def visit_const; end
  # lib/spoom/deadcode/indexer.rb:149:6-156:9
  def visit_const_path_field; end
  # lib/spoom/deadcode/indexer.rb:159:6-164:9
  def visit_def; end
  # lib/spoom/deadcode/indexer.rb:167:6-180:9
  def visit_field; end
  # lib/spoom/deadcode/indexer.rb:183:6-192:9
  def visit_module; end
  # lib/spoom/deadcode/indexer.rb:195:6-201:9
  def visit_opassign; end
  # lib/spoom/deadcode/indexer.rb:204:6-240:9
  def visit_send; end
  # lib/spoom/deadcode/indexer.rb:243:6-249:9
  def visit_symbol_literal; end
  # lib/spoom/deadcode/indexer.rb:252:6-254:9
  def visit_top_const_field; end
  # lib/spoom/deadcode/indexer.rb:257:6-271:9
  def visit_var_field; end
  # lib/spoom/deadcode/indexer.rb:274:6-276:9
  def visit_vcall; end
  # lib/spoom/deadcode/indexer.rb:281:6-290:9
  def define_attr_reader; end
  # lib/spoom/deadcode/indexer.rb:293:6-302:9
  def define_attr_writer; end
  # lib/spoom/deadcode/indexer.rb:305:6-314:9
  def define_class; end
  # lib/spoom/deadcode/indexer.rb:317:6-326:9
  def define_constant; end
  # lib/spoom/deadcode/indexer.rb:329:6-338:9
  def define_method; end
  # lib/spoom/deadcode/indexer.rb:341:6-350:9
  def define_module; end
  # lib/spoom/deadcode/indexer.rb:355:6-357:9
  def reference_constant; end
  # lib/spoom/deadcode/indexer.rb:360:6-362:9
  def reference_method; end
  # lib/spoom/deadcode/indexer.rb:367:6-374:9
  def node_string; end
  # lib/spoom/deadcode/indexer.rb:377:6-379:9
  def node_location; end
  # lib/spoom/deadcode/indexer.rb:382:6-384:9
  def symbol_string; end
  # lib/spoom/deadcode/indexer.rb:391:6-400:9
  def call_args; end
end
# lib/spoom/deadcode.rb:32:4-32:35
class Spoom::Deadcode::IndexerError < Spoom::Deadcode::Error
end
# lib/spoom/deadcode.rb:31:4-31:34
class Spoom::Deadcode::ParserError < Spoom::Deadcode::Error
end
# lib/spoom/deadcode/plugins/base.rb:8:4-199:7
module Spoom::Deadcode::Plugins
end
# lib/spoom/deadcode/plugins/ruby.rb:6:4-62:7
module Spoom::Deadcode::Plugins
end
# lib/spoom/deadcode/plugins/base.rb:9:6-198:9
class Spoom::Deadcode::Plugins::Base
  # lib/spoom/deadcode/plugins/base.rb:34:10-36:13
  def ignore_method_names; end
  # lib/spoom/deadcode/plugins/base.rb:41:10-53:13
  def save_names_and_patterns; end
  # lib/spoom/deadcode/plugins/base.rb:72:8-74:11
  def on_define_accessor; end
  # lib/spoom/deadcode/plugins/base.rb:90:8-92:11
  def on_define_class; end
  # lib/spoom/deadcode/plugins/base.rb:108:8-110:11
  def on_define_constant; end
  # lib/spoom/deadcode/plugins/base.rb:128:8-130:11
  def on_define_method; end
  # lib/spoom/deadcode/plugins/base.rb:146:8-148:11
  def on_define_module; end
  # lib/spoom/deadcode/plugins/base.rb:164:8-166:11
  def on_send; end
  # lib/spoom/deadcode/plugins/base.rb:171:8-173:11
  def ignored_method_name?; end
  # lib/spoom/deadcode/plugins/base.rb:176:8-178:11
  def names; end
  # lib/spoom/deadcode/plugins/base.rb:181:8-183:11
  def ignored_name?; end
  # lib/spoom/deadcode/plugins/base.rb:186:8-188:11
  def patterns; end
  # lib/spoom/deadcode/plugins/base.rb:191:8-197:11
  def reference_send_first_symbol_as_method; end
end
# lib/spoom/deadcode/plugins/ruby.rb:7:6-61:9
class Spoom::Deadcode::Plugins::Ruby < Spoom::Deadcode::Plugins::Base
  # lib/spoom/deadcode/plugins/ruby.rb:24:8-44:11
  def on_send; end
  # lib/spoom/deadcode/plugins/ruby.rb:49:8-60:11
  def reference_symbol_as_constant; end
end
# lib/spoom/deadcode/reference.rb:7:4-32:7
class Spoom::Deadcode::Reference < Ref[T::Struct]
  # lib/spoom/deadcode/reference.rb:24:6-26:9
  def constant?; end
  # lib/spoom/deadcode/reference.rb:29:6-31:9
  def method?; end
  # lib/spoom/deadcode/reference.rb:17:6-17:23
  const :kind, type: Kind
  # lib/spoom/deadcode/reference.rb:18:6-18:25
  const :name, type: String
  # lib/spoom/deadcode/reference.rb:19:6-19:31
  const :location, type: Location
end
# lib/spoom/deadcode/reference.rb:10:6-15:9
class Spoom::Deadcode::Reference::Kind < Ref[T::Enum]
end
# lib/spoom/deadcode/send.rb:8:4-16:7
class Spoom::Deadcode::Send < Ref[T::Struct]
  # lib/spoom/deadcode/send.rb:11:6-11:35
  const :node, type: SyntaxTree::Node
  # lib/spoom/deadcode/send.rb:12:6-12:25
  const :name, type: String
  # lib/spoom/deadcode/send.rb:13:6-13:60
  const :recv, type: T.nilable(SyntaxTree::Node)
  # lib/spoom/deadcode/send.rb:14:6-14:58
  const :args, type: T::Array[SyntaxTree::Node]
  # lib/spoom/deadcode/send.rb:15:6-15:61
  const :block, type: T.nilable(SyntaxTree::Node)
end
# lib/spoom.rb:12:2-12:34
class Spoom::Error < Ref[StandardError]
end
# lib/spoom/context/exec.rb:5:2-23:5
class Spoom::ExecResult < Ref[T::Struct]
  # lib/spoom/context/exec.rb:14:4-22:7
  def to_s; end
  # lib/spoom/context/exec.rb:8:4-8:22
  const :out, type: String
  # lib/spoom/context/exec.rb:9:4-9:33
  const :err, type: T.nilable(String)
  # lib/spoom/context/exec.rb:10:4-10:29
  const :status, type: T::Boolean
  # lib/spoom/context/exec.rb:11:4-11:29
  const :exit_code, type: Integer
end
# lib/spoom/file_collector.rb:5:2-101:5
class Spoom::FileCollector
  # lib/spoom/file_collector.rb:9:16-9:22
  attr_reader :files
  # lib/spoom/file_collector.rb:26:4-31:7
  def initialize; end
  # lib/spoom/file_collector.rb:34:4-36:7
  def visit_paths; end
  # lib/spoom/file_collector.rb:39:4-51:7
  def visit_path; end
  # lib/spoom/file_collector.rb:56:4-58:7
  def clean_path; end
  # lib/spoom/file_collector.rb:61:4-65:7
  def visit_file; end
  # lib/spoom/file_collector.rb:68:4-70:7
  def visit_directory; end
  # lib/spoom/file_collector.rb:73:4-85:7
  def excluded_file?; end
  # lib/spoom/file_collector.rb:88:4-94:7
  def excluded_path?; end
  # lib/spoom/file_collector.rb:97:4-100:7
  def mime_type_for; end
end
# lib/spoom/file_tree.rb:6:2-282:5
class Spoom::FileTree
  # lib/spoom/file_tree.rb:10:4-13:7
  def initialize; end
  # lib/spoom/file_tree.rb:17:4-19:7
  def add_paths; end
  # lib/spoom/file_tree.rb:25:4-35:7
  def add_path; end
  # lib/spoom/file_tree.rb:39:4-41:7
  def roots; end
  # lib/spoom/file_tree.rb:45:4-49:7
  def nodes; end
  # lib/spoom/file_tree.rb:53:4-55:7
  def paths; end
  # lib/spoom/file_tree.rb:59:4-63:7
  def nodes_strictnesses; end
  # lib/spoom/file_tree.rb:67:4-71:7
  def nodes_strictness_scores; end
  # lib/spoom/file_tree.rb:75:4-77:7
  def paths_strictness_scores; end
  # lib/spoom/file_tree.rb:80:4-83:7
  def print; end
  # lib/spoom/file_tree.rb:86:4-91:7
  def print_with_strictnesses; end
end
# lib/spoom/file_tree.rb:140:4-157:7
class Spoom::FileTree::CollectNodes < Spoom::FileTree::Visitor
  # lib/spoom/file_tree.rb:144:18-144:24
  attr_reader :nodes
  # lib/spoom/file_tree.rb:147:6-150:9
  def initialize; end
  # lib/spoom/file_tree.rb:153:6-156:9
  def visit_node; end
end
# lib/spoom/file_tree.rb:183:4-223:7
class Spoom::FileTree::CollectScores < Spoom::FileTree::CollectStrictnesses
  # lib/spoom/file_tree.rb:187:18-187:25
  attr_reader :scores
  # lib/spoom/file_tree.rb:190:6-194:9
  def initialize; end
  # lib/spoom/file_tree.rb:197:6-201:9
  def visit_node; end
  # lib/spoom/file_tree.rb:206:6-212:9
  def node_score; end
  # lib/spoom/file_tree.rb:215:6-222:9
  def strictness_score; end
end
# lib/spoom/file_tree.rb:160:4-180:7
class Spoom::FileTree::CollectStrictnesses < Spoom::FileTree::Visitor
  # lib/spoom/file_tree.rb:164:18-164:31
  attr_reader :strictnesses
  # lib/spoom/file_tree.rb:167:6-171:9
  def initialize; end
  # lib/spoom/file_tree.rb:174:6-179:9
  def visit_node; end
end
# lib/spoom/file_tree.rb:94:4-114:7
class Spoom::FileTree::Node < Ref[T::Struct]
  # lib/spoom/file_tree.rb:108:6-113:9
  def path; end
  # lib/spoom/file_tree.rb:98:6-98:36
  const :parent, type: T.nilable(Node)
  # lib/spoom/file_tree.rb:101:6-101:25
  const :name, type: String
  # lib/spoom/file_tree.rb:104:6-104:57
  const :children, type: T::Hash[String, Node]
end
# lib/spoom/file_tree.rb:228:4-281:7
class Spoom::FileTree::Printer < Spoom::FileTree::Visitor
  # lib/spoom/file_tree.rb:238:6-243:9
  def initialize; end
  # lib/spoom/file_tree.rb:246:6-266:9
  def visit_node; end
  # lib/spoom/file_tree.rb:271:6-280:9
  def strictness_color; end
end
# lib/spoom/file_tree.rb:117:4-137:7
class Spoom::FileTree::Visitor
  # lib/spoom/file_tree.rb:124:6-126:9
  def visit_tree; end
  # lib/spoom/file_tree.rb:129:6-131:9
  def visit_node; end
  # lib/spoom/file_tree.rb:134:6-136:9
  def visit_nodes; end
end
# lib/spoom/context/git.rb:5:2-31:5
module Spoom::Git
end
# lib/spoom/context/git.rb:6:4-30:7
class Spoom::Git::Commit < Ref[T::Struct]
  # lib/spoom/context/git.rb:14:8-20:11
  def parse_line; end
  # lib/spoom/context/git.rb:27:6-29:9
  def timestamp; end
  # lib/spoom/context/git.rb:23:6-23:24
  const :sha, type: String
  # lib/spoom/context/git.rb:24:6-24:23
  const :time, type: Time
end
# lib/spoom/sorbet/lsp/base.rb:5:2-74:5
module Spoom::LSP
end
# lib/spoom/sorbet/lsp/errors.rb:5:2-69:5
module Spoom::LSP
end
# lib/spoom/sorbet/lsp/structures.rb:8:2-365:5
module Spoom::LSP
end
# lib/spoom/sorbet/lsp.rb:12:2-237:5
module Spoom::LSP
end
# lib/spoom/sorbet/lsp.rb:13:4-236:7
class Spoom::LSP::Client
  # lib/spoom/sorbet/lsp.rb:17:6-24:9
  def initialize; end
  # lib/spoom/sorbet/lsp.rb:27:6-29:9
  def next_id; end
  # lib/spoom/sorbet/lsp.rb:32:6-34:9
  def send_raw; end
  # lib/spoom/sorbet/lsp.rb:37:6-40:9
  def send; end
  # lib/spoom/sorbet/lsp.rb:43:6-51:9
  def read_raw; end
  # lib/spoom/sorbet/lsp.rb:54:6-67:9
  def read; end
  # lib/spoom/sorbet/lsp.rb:72:6-86:9
  def open; end
  # lib/spoom/sorbet/lsp.rb:89:6-107:9
  def hover; end
  # lib/spoom/sorbet/lsp.rb:110:6-128:9
  def signatures; end
  # lib/spoom/sorbet/lsp.rb:131:6-149:9
  def definitions; end
  # lib/spoom/sorbet/lsp.rb:152:6-170:9
  def type_definitions; end
  # lib/spoom/sorbet/lsp.rb:173:6-194:9
  def references; end
  # lib/spoom/sorbet/lsp.rb:197:6-209:9
  def symbols; end
  # lib/spoom/sorbet/lsp.rb:212:6-226:9
  def document_symbols; end
  # lib/spoom/sorbet/lsp.rb:229:6-235:9
  def close; end
end
# lib/spoom/sorbet/lsp/structures.rb:178:4-210:7
class Spoom::LSP::Diagnostic < Ref[T::Struct]
  # lib/spoom/sorbet/lsp/structures.rb:191:8-198:11
  def from_json; end
  # lib/spoom/sorbet/lsp/structures.rb:202:6-204:9
  def accept_printer; end
  # lib/spoom/sorbet/lsp/structures.rb:207:6-209:9
  def to_s; end
  # lib/spoom/sorbet/lsp/structures.rb:182:6-182:30
  const :range, type: LSP::Range
  # lib/spoom/sorbet/lsp/structures.rb:183:6-183:26
  const :code, type: Integer
  # lib/spoom/sorbet/lsp/structures.rb:184:6-184:28
  const :message, type: String
  # lib/spoom/sorbet/lsp/structures.rb:185:6-185:33
  const :informations, type: Object
end
# lib/spoom/sorbet/lsp/structures.rb:212:4-307:7
class Spoom::LSP::DocumentSymbol < Ref[T::Struct]
  # lib/spoom/sorbet/lsp/structures.rb:227:8-236:11
  def from_json; end
  # lib/spoom/sorbet/lsp/structures.rb:240:6-264:9
  def accept_printer; end
  # lib/spoom/sorbet/lsp/structures.rb:267:6-269:9
  def to_s; end
  # lib/spoom/sorbet/lsp/structures.rb:272:6-274:9
  def kind_string; end
  # lib/spoom/sorbet/lsp/structures.rb:216:6-216:25
  const :name, type: String
  # lib/spoom/sorbet/lsp/structures.rb:217:6-217:38
  const :detail, type: T.nilable(String)
  # lib/spoom/sorbet/lsp/structures.rb:218:6-218:26
  const :kind, type: Integer
  # lib/spoom/sorbet/lsp/structures.rb:219:6-219:42
  const :location, type: T.nilable(Location)
  # lib/spoom/sorbet/lsp/structures.rb:220:6-220:36
  const :range, type: T.nilable(Range)
  # lib/spoom/sorbet/lsp/structures.rb:221:6-221:47
  const :children, type: T::Array[DocumentSymbol]
end
# lib/spoom/sorbet/lsp/errors.rb:6:4-38:7
class Spoom::LSP::Error < Ref[StandardError]
end
# lib/spoom/sorbet/lsp/errors.rb:7:6-7:36
class Spoom::LSP::Error::AlreadyOpen < Spoom::LSP::Error
end
# lib/spoom/sorbet/lsp/errors.rb:8:6-8:35
class Spoom::LSP::Error::BadHeaders < Spoom::LSP::Error
end
# lib/spoom/sorbet/lsp/errors.rb:10:6-37:9
class Spoom::LSP::Error::Diagnostics < Spoom::LSP::Error
  # lib/spoom/sorbet/lsp/errors.rb:14:20-14:24
  attr_reader :uri
  # lib/spoom/sorbet/lsp/errors.rb:17:20-17:32
  attr_reader :diagnostics
  # lib/spoom/sorbet/lsp/errors.rb:23:10-28:13
  def from_json; end
  # lib/spoom/sorbet/lsp/errors.rb:32:8-36:11
  def initialize; end
end
# lib/spoom/sorbet/lsp/structures.rb:19:4-48:7
class Spoom::LSP::Hover < Ref[T::Struct]
  # lib/spoom/sorbet/lsp/structures.rb:30:8-35:11
  def from_json; end
  # lib/spoom/sorbet/lsp/structures.rb:39:6-42:9
  def accept_printer; end
  # lib/spoom/sorbet/lsp/structures.rb:45:6-47:9
  def to_s; end
  # lib/spoom/sorbet/lsp/structures.rb:23:6-23:29
  const :contents, type: String
  # lib/spoom/sorbet/lsp/structures.rb:24:6-24:36
  const :range, type: T.nilable(Range)
end
# lib/spoom/sorbet/lsp/structures.rb:112:4-141:7
class Spoom::LSP::Location < Ref[T::Struct]
  # lib/spoom/sorbet/lsp/structures.rb:123:8-128:11
  def from_json; end
  # lib/spoom/sorbet/lsp/structures.rb:132:6-135:9
  def accept_printer; end
  # lib/spoom/sorbet/lsp/structures.rb:138:6-140:9
  def to_s; end
  # lib/spoom/sorbet/lsp/structures.rb:116:6-116:24
  const :uri, type: String
  # lib/spoom/sorbet/lsp/structures.rb:117:6-117:30
  const :range, type: LSP::Range
end
# lib/spoom/sorbet/lsp/base.rb:12:4-32:7
class Spoom::LSP::Message
  # lib/spoom/sorbet/lsp/base.rb:16:6-18:9
  def initialize; end
  # lib/spoom/sorbet/lsp/base.rb:21:6-26:9
  def as_json; end
  # lib/spoom/sorbet/lsp/base.rb:29:6-31:9
  def to_json; end
end
# lib/spoom/sorbet/lsp/base.rb:58:4-73:7
class Spoom::LSP::Notification < Spoom::LSP::Message
  # lib/spoom/sorbet/lsp/base.rb:62:18-62:25
  attr_reader :method
  # lib/spoom/sorbet/lsp/base.rb:65:18-65:25
  attr_reader :params
  # lib/spoom/sorbet/lsp/base.rb:68:6-72:9
  def initialize; end
end
# lib/spoom/sorbet/lsp/structures.rb:50:4-78:7
class Spoom::LSP::Position < Ref[T::Struct]
  # lib/spoom/sorbet/lsp/structures.rb:61:8-66:11
  def from_json; end
  # lib/spoom/sorbet/lsp/structures.rb:70:6-72:9
  def accept_printer; end
  # lib/spoom/sorbet/lsp/structures.rb:75:6-77:9
  def to_s; end
  # lib/spoom/sorbet/lsp/structures.rb:54:6-54:26
  const :line, type: Integer
  # lib/spoom/sorbet/lsp/structures.rb:55:6-55:26
  const :char, type: Integer
end
# lib/spoom/sorbet/lsp/structures.rb:9:4-17:7
module Spoom::LSP::PrintableSymbol
  # lib/spoom/sorbet/lsp/structures.rb:16:6-16:38
  def accept_printer; end
end
# lib/spoom/sorbet/lsp/structures.rb:80:4-110:7
class Spoom::LSP::Range < Ref[T::Struct]
  # lib/spoom/sorbet/lsp/structures.rb:91:8-96:11
  def from_json; end
  # lib/spoom/sorbet/lsp/structures.rb:100:6-104:9
  def accept_printer; end
  # lib/spoom/sorbet/lsp/structures.rb:107:6-109:9
  def to_s; end
  # lib/spoom/sorbet/lsp/structures.rb:84:6-84:28
  const :start, type: Position
  # lib/spoom/sorbet/lsp/structures.rb:85:6-85:26
  const :end, type: Position
end
# lib/spoom/sorbet/lsp/base.rb:37:4-53:7
class Spoom::LSP::Request < Spoom::LSP::Message
  # lib/spoom/sorbet/lsp/base.rb:41:18-41:21
  attr_reader :id
  # lib/spoom/sorbet/lsp/base.rb:44:18-44:25
  attr_reader :params
  # lib/spoom/sorbet/lsp/base.rb:47:6-52:9
  def initialize; end
end
# lib/spoom/sorbet/lsp/errors.rb:40:4-68:7
class Spoom::LSP::ResponseError < Spoom::LSP::Error
  # lib/spoom/sorbet/lsp/errors.rb:44:18-44:23
  attr_reader :code
  # lib/spoom/sorbet/lsp/errors.rb:47:18-47:23
  attr_reader :data
  # lib/spoom/sorbet/lsp/errors.rb:53:8-59:11
  def from_json; end
  # lib/spoom/sorbet/lsp/errors.rb:63:6-67:9
  def initialize; end
end
# lib/spoom/sorbet/lsp/structures.rb:143:4-176:7
class Spoom::LSP::SignatureHelp < Ref[T::Struct]
  # lib/spoom/sorbet/lsp/structures.rb:155:8-161:11
  def from_json; end
  # lib/spoom/sorbet/lsp/structures.rb:165:6-170:9
  def accept_printer; end
  # lib/spoom/sorbet/lsp/structures.rb:173:6-175:9
  def to_s; end
  # lib/spoom/sorbet/lsp/structures.rb:147:6-147:37
  const :label, type: T.nilable(String)
  # lib/spoom/sorbet/lsp/structures.rb:148:6-148:24
  const :doc, type: Object
  # lib/spoom/sorbet/lsp/structures.rb:149:6-149:40
  const :params, type: T::Array[T.untyped]
end
# lib/spoom/sorbet/lsp/structures.rb:309:4-364:7
class Spoom::LSP::SymbolPrinter < Spoom::Printer
  # lib/spoom/sorbet/lsp/structures.rb:313:18-313:23
  attr_reader :seen
  # lib/spoom/sorbet/lsp/structures.rb:316:20-316:27
  attr_accessor :prefix
  # lib/spoom/sorbet/lsp/structures.rb:326:6-333:9
  def initialize; end
  # lib/spoom/sorbet/lsp/structures.rb:336:6-340:9
  def print_object; end
  # lib/spoom/sorbet/lsp/structures.rb:343:6-345:9
  def print_objects; end
  # lib/spoom/sorbet/lsp/structures.rb:348:6-353:9
  def clean_uri; end
  # lib/spoom/sorbet/lsp/structures.rb:356:6-363:9
  def print_list; end
end
# lib/spoom/location.rb:5:2-60:5
class Spoom::Location
  # lib/spoom/location.rb:27:16-27:21
  attr_reader :file
  # lib/spoom/location.rb:30:16-30:27
  attr_reader :start_line
  # lib/spoom/location.rb:30:29-30:42
  attr_reader :start_column
  # lib/spoom/location.rb:30:44-30:53
  attr_reader :end_line
  # lib/spoom/location.rb:30:55-30:66
  attr_reader :end_column
  # lib/spoom/location.rb:16:6-18:9
  def none; end
  # lib/spoom/location.rb:21:6-23:9
  def from_syntax_tree; end
  # lib/spoom/location.rb:41:4-47:7
  def initialize; end
  # lib/spoom/location.rb:50:4-54:7
  def <=>; end
  # lib/spoom/location.rb:57:4-59:7
  def to_s; end
end
# lib/spoom/location.rb:10:4-10:43
class Spoom::Location::LocationError < Spoom::Error
end
# lib/spoom/model/builder.rb:5:2-170:5
class Spoom::Model
end
# lib/spoom/model/model.rb:5:2-364:5
class Spoom::Model
  # lib/spoom/model/model.rb:220:16-220:23
  attr_reader :scopes
  # lib/spoom/model/model.rb:210:6-216:9
  def merge; end
  # lib/spoom/model/model.rb:223:4-225:7
  def initialize; end
  # lib/spoom/model/model.rb:228:4-230:7
  def add_class; end
  # lib/spoom/model/model.rb:233:4-235:7
  def add_module; end
  # lib/spoom/model/model.rb:238:4-250:7
  def resolve_ancestors!; end
  # lib/spoom/model/model.rb:253:4-259:7
  def resolve_superclass; end
  # lib/spoom/model/model.rb:262:4-269:7
  def resolve_includes; end
  # lib/spoom/model/model.rb:272:4-291:7
  def resolve_name; end
  # lib/spoom/model/model.rb:294:4-306:7
  def classes; end
  # lib/spoom/model/model.rb:309:4-321:7
  def modules; end
  # lib/spoom/model/model.rb:324:4-337:7
  def structs; end
  # lib/spoom/model/model.rb:340:4-350:7
  def subclasses_of; end
  # lib/spoom/model/model.rb:353:4-363:7
  def descendants_of; end
end
# lib/spoom/model/printer.rb:5:2-116:5
class Spoom::Model
end
# lib/spoom/model/visitor.rb:5:2-107:5
class Spoom::Model
  # lib/spoom/model/visitor.rb:64:4-66:7
  def accept; end
end
# lib/spoom/model/model.rb:133:4-154:7
class Spoom::Model::Attr < Spoom::Model::Symbol
  # lib/spoom/model/model.rb:137:18-137:23
  attr_reader :kind
  # lib/spoom/model/model.rb:140:18-140:23
  attr_reader :name
  # lib/spoom/model/model.rb:143:6-148:9
  def initialize; end
  # lib/spoom/model/model.rb:151:6-153:9
  def to_s; end
end
# lib/spoom/model/visitor.rb:87:4-92:7
class Spoom::Model::Attr
  # lib/spoom/model/visitor.rb:89:6-91:9
  def accept; end
end
# lib/spoom/model/builder.rb:6:4-159:7
class Spoom::Model::Builder < Ref[SyntaxTree::Visitor]
  # lib/spoom/model/builder.rb:10:6-19:9
  def initialize; end
  # lib/spoom/model/builder.rb:22:6-34:9
  def visit_class; end
  # lib/spoom/model/builder.rb:37:6-46:9
  def visit_module; end
  # lib/spoom/model/builder.rb:49:6-52:9
  def visit_def; end
  # lib/spoom/model/builder.rb:55:6-64:9
  def visit_call; end
  # lib/spoom/model/builder.rb:67:6-76:9
  def visit_command; end
  # lib/spoom/model/builder.rb:79:6-89:9
  def visit_command_call; end
  # lib/spoom/model/builder.rb:92:6-94:9
  def visit_vcall; end
  # lib/spoom/model/builder.rb:99:6-117:9
  def visit_send; end
  # lib/spoom/model/builder.rb:124:6-133:9
  def call_args; end
  # lib/spoom/model/builder.rb:136:6-138:9
  def current_namespace; end
  # lib/spoom/model/builder.rb:141:6-143:9
  def current_scope; end
  # lib/spoom/model/builder.rb:146:6-148:9
  def node_loc; end
  # lib/spoom/model/builder.rb:151:6-158:9
  def node_string; end
end
# lib/spoom/model/model.rb:87:4-131:7
class Spoom::Model::Class < Spoom::Model::Scope
  # lib/spoom/model/model.rb:91:20-91:31
  attr_accessor :superclass
  # lib/spoom/model/model.rb:94:6-98:9
  def initialize; end
  # lib/spoom/model/model.rb:101:6-106:9
  def subclass_of?; end
  # lib/spoom/model/model.rb:109:6-114:9
  def descendant_of?; end
  # lib/spoom/model/model.rb:117:6-130:9
  def to_s; end
end
# lib/spoom/model/visitor.rb:73:4-78:7
class Spoom::Model::Class
  # lib/spoom/model/visitor.rb:75:6-77:9
  def accept; end
end
# lib/spoom/model/model.rb:156:4-173:7
class Spoom::Model::Method < Spoom::Model::Symbol
  # lib/spoom/model/model.rb:160:18-160:23
  attr_reader :name
  # lib/spoom/model/model.rb:163:6-167:9
  def initialize; end
  # lib/spoom/model/model.rb:170:6-172:9
  def to_s; end
end
# lib/spoom/model/visitor.rb:94:4-99:7
class Spoom::Model::Method
  # lib/spoom/model/visitor.rb:96:6-98:9
  def accept; end
end
# lib/spoom/model/model.rb:78:4-85:7
class Spoom::Model::Module < Spoom::Model::Scope
  # lib/spoom/model/model.rb:82:6-84:9
  def to_s; end
end
# lib/spoom/model/visitor.rb:80:4-85:7
class Spoom::Model::Module
  # lib/spoom/model/visitor.rb:82:6-84:9
  def accept; end
end
# lib/spoom/model/printer.rb:6:4-115:7
class Spoom::Model::Printer < Spoom::Model::Visitor
  # lib/spoom/model/printer.rb:10:18-10:22
  attr_reader :out
  # lib/spoom/model/printer.rb:13:6-18:9
  def initialize; end
  # lib/spoom/model/printer.rb:23:6-25:9
  def indent; end
  # lib/spoom/model/printer.rb:28:6-30:9
  def dedent; end
  # lib/spoom/model/printer.rb:33:6-37:9
  def print; end
  # lib/spoom/model/printer.rb:40:6-43:9
  def printn; end
  # lib/spoom/model/printer.rb:46:6-52:9
  def printl; end
  # lib/spoom/model/printer.rb:55:6-58:9
  def printt; end
  # lib/spoom/model/printer.rb:63:6-78:9
  def visit_class; end
  # lib/spoom/model/printer.rb:81:6-88:9
  def visit_module; end
  # lib/spoom/model/printer.rb:93:6-96:9
  def visit_attr; end
  # lib/spoom/model/printer.rb:99:6-102:9
  def visit_method; end
  # lib/spoom/model/printer.rb:105:6-114:9
  def visit_prop; end
end
# lib/spoom/model/model.rb:175:4-204:7
class Spoom::Model::Prop < Spoom::Model::Symbol
  # lib/spoom/model/model.rb:179:18-179:23
  attr_reader :name
  # lib/spoom/model/model.rb:182:18-182:23
  attr_reader :type
  # lib/spoom/model/model.rb:185:18-185:28
  attr_reader :read_only
  # lib/spoom/model/model.rb:188:6-194:9
  def initialize; end
  # lib/spoom/model/model.rb:197:6-203:9
  def to_s; end
end
# lib/spoom/model/visitor.rb:101:4-106:7
class Spoom::Model::Prop
  # lib/spoom/model/visitor.rb:103:6-105:9
  def accept; end
end
# lib/spoom/model/model.rb:23:4-38:7
class Spoom::Model::Ref
  # lib/spoom/model/model.rb:27:18-27:28
  attr_reader :full_name
  # lib/spoom/model/model.rb:30:6-32:9
  def initialize; end
  # lib/spoom/model/model.rb:35:6-37:9
  def to_s; end
end
# lib/spoom/model/model.rb:40:4-76:7
class Spoom::Model::Scope < Spoom::Model::Symbol
  # lib/spoom/model/model.rb:47:18-47:28
  attr_reader :full_name
  # lib/spoom/model/model.rb:50:18-50:27
  attr_reader :includes
  # lib/spoom/model/model.rb:53:18-53:24
  attr_reader :attrs
  # lib/spoom/model/model.rb:56:18-56:23
  attr_reader :defs
  # lib/spoom/model/model.rb:59:18-59:24
  attr_reader :props
  # lib/spoom/model/model.rb:62:6-70:9
  def initialize; end
  # lib/spoom/model/model.rb:73:6-75:9
  def descendant_of?; end
end
# lib/spoom/model/builder.rb:161:4-169:7
class Spoom::Model::Send < Ref[T::Struct]
  # lib/spoom/model/builder.rb:164:6-164:35
  const :node, type: SyntaxTree::Node
  # lib/spoom/model/builder.rb:165:6-165:25
  const :name, type: String
  # lib/spoom/model/builder.rb:166:6-166:60
  const :recv, type: T.nilable(SyntaxTree::Node)
  # lib/spoom/model/builder.rb:167:6-167:58
  const :args, type: T::Array[SyntaxTree::Node]
  # lib/spoom/model/builder.rb:168:6-168:61
  const :block, type: T.nilable(SyntaxTree::Node)
end
# lib/spoom/model/model.rb:8:4-21:7
class Spoom::Model::Symbol
  # lib/spoom/model/model.rb:15:18-15:27
  attr_reader :location
  # lib/spoom/model/model.rb:18:6-20:9
  def initialize; end
end
# lib/spoom/model/visitor.rb:68:4-71:7
class Spoom::Model::Symbol
  # lib/spoom/model/visitor.rb:70:6-70:30
  def accept; end
end
# lib/spoom/model/visitor.rb:6:4-61:7
class Spoom::Model::Visitor
  # lib/spoom/model/visitor.rb:13:6-15:9
  def visit; end
  # lib/spoom/model/visitor.rb:18:6-20:9
  def visit_all; end
  # lib/spoom/model/visitor.rb:23:6-27:9
  def visit_model; end
  # lib/spoom/model/visitor.rb:32:6-36:9
  def visit_class; end
  # lib/spoom/model/visitor.rb:39:6-43:9
  def visit_module; end
  # lib/spoom/model/visitor.rb:48:6-50:9
  def visit_attr; end
  # lib/spoom/model/visitor.rb:53:6-55:9
  def visit_method; end
  # lib/spoom/model/visitor.rb:58:6-60:9
  def visit_prop; end
end
# lib/spoom/printer.rb:7:2-83:5
class Spoom::Printer
  # lib/spoom/printer.rb:14:18-14:22
  attr_accessor :out
  # lib/spoom/printer.rb:17:4-21:7
  def initialize; end
  # lib/spoom/printer.rb:25:4-27:7
  def indent; end
  # lib/spoom/printer.rb:31:4-33:7
  def dedent; end
  # lib/spoom/printer.rb:37:4-41:7
  def print; end
  # lib/spoom/printer.rb:47:4-52:7
  def print_colored; end
  # lib/spoom/printer.rb:56:4-58:7
  def printn; end
  # lib/spoom/printer.rb:62:4-68:7
  def printl; end
  # lib/spoom/printer.rb:72:4-74:7
  def printt; end
  # lib/spoom/printer.rb:78:4-82:7
  def colorize; end
end
# lib/spoom/sorbet/config.rb:5:2-155:5
module Spoom::Sorbet
end
# lib/spoom/sorbet/errors.rb:5:2-174:5
module Spoom::Sorbet
end
# lib/spoom/sorbet/metrics.rb:7:2-34:5
module Spoom::Sorbet
end
# lib/spoom/sorbet/sigils.rb:8:2-90:5
module Spoom::Sorbet
end
# lib/spoom/sorbet.rb:13:2-43:5
module Spoom::Sorbet
end
# lib/spoom/sorbet/config.rb:26:4-154:7
class Spoom::Sorbet::Config
  # lib/spoom/sorbet/config.rb:32:20-32:26
  attr_accessor :paths
  # lib/spoom/sorbet/config.rb:32:28-32:35
  attr_accessor :ignore
  # lib/spoom/sorbet/config.rb:32:37-32:56
  attr_accessor :allowed_extensions
  # lib/spoom/sorbet/config.rb:35:20-35:30
  attr_accessor :no_stdlib
  # lib/spoom/sorbet/config.rb:38:6-43:9
  def initialize; end
  # lib/spoom/sorbet/config.rb:46:6-53:9
  def copy; end
  # lib/spoom/sorbet/config.rb:68:6-75:9
  def options_string; end
  # lib/spoom/sorbet/config.rb:81:8-83:11
  def parse_file; end
  # lib/spoom/sorbet/config.rb:86:8-145:11
  def parse_string; end
  # lib/spoom/sorbet/config.rb:150:8-152:11
  def parse_option; end
end
# lib/spoom/sorbet.rb:14:4-34:7
class Spoom::Sorbet::Error < Ref[StandardError]
  # lib/spoom/sorbet.rb:21:18-21:25
  attr_reader :result
  # lib/spoom/sorbet.rb:29:6-33:9
  def initialize; end
end
# lib/spoom/sorbet.rb:17:6-17:31
class Spoom::Sorbet::Error::Killed < Spoom::Sorbet::Error
end
# lib/spoom/sorbet.rb:18:6-18:33
class Spoom::Sorbet::Error::Segfault < Spoom::Sorbet::Error
end
# lib/spoom/sorbet/errors.rb:6:4-173:7
module Spoom::Sorbet::Errors
  # lib/spoom/sorbet/errors.rb:13:8-15:11
  def sort_errors_by_code; end
end
# lib/spoom/sorbet/errors.rb:125:6-172:9
class Spoom::Sorbet::Errors::Error
  # lib/spoom/sorbet/errors.rb:130:20-130:25
  attr_reader :file
  # lib/spoom/sorbet/errors.rb:130:27-130:35
  attr_reader :message
  # lib/spoom/sorbet/errors.rb:133:20-133:25
  attr_reader :line
  # lib/spoom/sorbet/errors.rb:133:27-133:32
  attr_reader :code
  # lib/spoom/sorbet/errors.rb:136:20-136:25
  attr_reader :more
  # lib/spoom/sorbet/errors.rb:140:20-140:46
  attr_reader :files_from_error_sections
  # lib/spoom/sorbet/errors.rb:151:8-158:11
  def initialize; end
  # lib/spoom/sorbet/errors.rb:162:8-166:11
  def <=>; end
  # lib/spoom/sorbet/errors.rb:169:8-171:11
  def to_s; end
end
# lib/spoom/sorbet/errors.rb:18:6-123:9
class Spoom::Sorbet::Errors::Parser
  # lib/spoom/sorbet/errors.rb:36:10-39:13
  def parse_string; end
  # lib/spoom/sorbet/errors.rb:43:8-47:11
  def initialize; end
  # lib/spoom/sorbet/errors.rb:50:8-68:11
  def parse; end
  # lib/spoom/sorbet/errors.rb:73:8-87:11
  def error_line_match_regexp; end
  # lib/spoom/sorbet/errors.rb:90:8-96:11
  def match_error_line; end
  # lib/spoom/sorbet/errors.rb:99:8-103:11
  def open_error; end
  # lib/spoom/sorbet/errors.rb:106:8-111:11
  def close_error; end
  # lib/spoom/sorbet/errors.rb:114:8-122:11
  def append_error; end
end
# lib/spoom/sorbet/metrics.rb:8:4-33:7
module Spoom::Sorbet::MetricsParser
  # lib/spoom/sorbet/metrics.rb:15:8-17:11
  def parse_file; end
  # lib/spoom/sorbet/metrics.rb:20:8-22:11
  def parse_string; end
  # lib/spoom/sorbet/metrics.rb:25:8-31:11
  def parse_hash; end
end
# lib/spoom/sorbet/sigils.rb:9:4-89:7
module Spoom::Sorbet::Sigils
  # lib/spoom/sorbet/sigils.rb:38:8-40:11
  def sigil_string; end
  # lib/spoom/sorbet/sigils.rb:44:8-46:11
  def valid_strictness?; end
  # lib/spoom/sorbet/sigils.rb:50:8-52:11
  def strictness_in_content; end
  # lib/spoom/sorbet/sigils.rb:56:8-58:11
  def update_sigil; end
  # lib/spoom/sorbet/sigils.rb:63:8-68:11
  def file_strictness; end
  # lib/spoom/sorbet/sigils.rb:72:8-79:11
  def change_sigil_in_file; end
  # lib/spoom/sorbet/sigils.rb:83:8-87:11
  def change_sigil_in_files; end
end
# lib/spoom/timeline.rb:5:2-50:5
class Spoom::Timeline
  # lib/spoom/timeline.rb:9:4-13:7
  def initialize; end
  # lib/spoom/timeline.rb:17:4-19:7
  def ticks; end
  # lib/spoom/timeline.rb:23:4-32:7
  def months; end
  # lib/spoom/timeline.rb:36:4-49:7
  def commits_for_dates; end
end
