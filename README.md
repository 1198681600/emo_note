my_app/
├── android/             # Android相关的原生代码和配置文件
│   └── ...
├── ios/                 # iOS相关的原生代码和配置文件
│   └── ...
├── lib/                 # 主要的Dart代码存放目录
│   ├── assets/          # 静态资源，如图片、字体等
│   ├── constants/       # 项目常量定义
│   ├── models/          # 数据模型定义
│   ├── pages/           # 页面组件，每个页面一个文件夹
│   │   ├── home/
│   │   │   ├── home_page.dart
│   │   │   └── ...
│   │   ├── about/
│   │   │   └── about_page.dart
│   │   └── ...
│   ├── providers/       # 状态管理，如Provider或Riverpod的实现
│   ├── repositories/    # 数据仓库层，负责数据获取逻辑
│   ├── services/        # 网络服务、本地存储等服务类
│   ├── utils/           # 工具类和帮助函数
│   ├── widgets/         # 可复用UI组件
│   │   ├── buttons/
│   │   ├── cards/
│   │   └── ...
│   ├── app.dart         # 应用程序入口文件
│   └── main.dart        # 主函数入口
├── test/                # 单元测试和 widget 测试文件
│   └── ...
├── pubspec.yaml         # 项目配置文件，包含依赖、版本信息等
├── analysis_options.yaml # 分析器配置文件，定制代码规范检查
└── .gitignore            # Git忽略文件列表