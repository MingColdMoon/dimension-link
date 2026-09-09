import '../models/models.dart';

/// 本地演示数据，字段与接口文档资源对象对齐，供无 ApiClient 的测试使用。
class MockSeed {
  MockSeed._();

  static DateTime _ago({int hours = 0, int minutes = 0, int days = 0}) {
    return DateTime.now().subtract(Duration(days: days, hours: hours, minutes: minutes));
  }

  static const meId = 'u_me';

  static AppUser user(String id) => users().firstWhere((item) => item.id == id);

  static Circle circle(String id) => circles().firstWhere((item) => item.id == id);

  static List<AppUser> users() => [
        const AppUser(
          id: meId,
          nickname: '星野铃',
          handle: '@hoshi_suzu',
          bio: '插画练习生 / 偶尔也写一点短篇同人',
          signature: '今晚也要和星星说晚安。',
          emoji: '🎀',
          accentIndex: 0,
          followers: 1286,
          following: 86,
          level: 18,
          badges: ['绘圈新人王', '樱花祭签到', '次元认证'],
          password: '123456',
        ),
        const AppUser(
          id: 'u_tsukimi',
          nickname: '月见黑',
          handle: '@tsukimi',
          bio: '同人作者，主推乙女向与群像',
          signature: '黑猫出门时记得带伞。',
          emoji: '🐈‍⬛',
          accentIndex: 1,
          followers: 8420,
          following: 210,
          level: 32,
          badges: ['同人周榜', '连载中'],
          isFollowing: true,
        ),
        const AppUser(
          id: 'u_sakurai',
          nickname: '桜井澪',
          handle: '@mio_cos',
          bio: 'COSER · 周末出没漫展',
          signature: '假发和心脏都要梳顺。',
          emoji: '🌸',
          accentIndex: 5,
          followers: 22100,
          following: 340,
          level: 41,
          badges: ['漫展常驻', 'COS本命'],
          isFollowing: true,
        ),
        const AppUser(
          id: 'u_nanami',
          nickname: '七海音',
          handle: '@nanami_oto',
          bio: '声优切片收藏家，耳机不离身',
          signature: '今天的电台也有心跳。',
          emoji: '🎧',
          accentIndex: 2,
          followers: 5600,
          following: 401,
          level: 24,
          badges: ['耳语鉴定师'],
        ),
        const AppUser(
          id: 'u_kaede',
          nickname: '青叶枫',
          handle: '@kaede_live',
          bio: '游戏主播，夜场排位陪跑',
          signature: '掉分也要笑着打完这把。',
          emoji: '🍁',
          accentIndex: 3,
          followers: 15800,
          following: 99,
          level: 29,
          badges: ['开黑车头', '夜猫'],
        ),
        const AppUser(
          id: 'u_tanuki',
          nickname: '狸猫不吃鱼',
          handle: '@tanuki',
          bio: '番剧安利人，评论区常驻',
          signature: '这部真的会哭，先说好。',
          emoji: '🦝',
          accentIndex: 7,
          followers: 9300,
          following: 512,
          level: 27,
          badges: ['安利达人'],
        ),
      ];

  static List<Circle> circles() => const [
        Circle(
          id: 'c_doujin',
          name: '同人创作',
          emoji: '✒️',
          desc: '短篇、长篇、CP 考古，文字与分镜都在这里碰头。',
          memberCount: 12840,
          accentIndex: 1,
          tags: ['乙女', '群像', '无CP', '连载'],
          joined: true,
        ),
        Circle(
          id: 'c_cos',
          name: 'COSPLAY',
          emoji: '👗',
          desc: '妆造、道具、片场分享。出片请带标签。',
          memberCount: 20311,
          accentIndex: 0,
          tags: ['妆造', '漫展', '道具', '约拍'],
          joined: true,
        ),
        Circle(
          id: 'c_anime',
          name: '番剧安利',
          emoji: '📺',
          desc: '新番吐槽、神作回访、今晚看什么。',
          memberCount: 35602,
          accentIndex: 6,
          tags: ['新番', '神作', '催泪', '搞笑'],
          joined: true,
        ),
        Circle(
          id: 'c_art',
          name: '绘圈日常',
          emoji: '🎨',
          desc: '速写、厚涂、配色练习，互相摸摸头。',
          memberCount: 18770,
          accentIndex: 2,
          tags: ['速写', '厚涂', '练习', '约稿'],
        ),
        Circle(
          id: 'c_game',
          name: '游戏开黑',
          emoji: '🎮',
          desc: '缺一补三，语音温柔，别破防。',
          memberCount: 9904,
          accentIndex: 3,
          tags: ['排位', '休闲', '语音', '攻略'],
        ),
        Circle(
          id: 'c_voice',
          name: '声优电台',
          emoji: '🎙️',
          desc: '广播剧、角色歌、现场切片分享。',
          memberCount: 6408,
          accentIndex: 5,
          tags: ['广播剧', '角色歌', '现场'],
        ),
      ];

  static List<Post> posts() => [
        Post(
          id: 'p1',
          author: user('u_sakurai'),
          content: '漫展返图来啦～假发被风吹成了小龙卷，但眼睛里的星星是真的。谢谢帮我提裙撑的路人妹妹！',
          createdAt: _ago(hours: 2),
          mood: MoodTag.excited,
          circle: circle('c_cos'),
          imageHue: 330,
          imageTitle: '樱色舞台',
          liked: true,
          starred: false,
          likeCount: 3,
          starCount: 1,
          commentCount: 2,
          comments: [
            Comment(
              id: 'c1',
              user: user('u_tsukimi'),
              content: '裙撑绝了，下一场还出这个吗？',
              createdAt: _ago(hours: 1, minutes: 40),
            ),
            Comment(
              id: 'c2',
              user: user(meId),
              content: '星星眼睛好会！求妆造分享～',
              createdAt: _ago(hours: 1),
            ),
          ],
        ),
        Post(
          id: 'p2',
          author: user('u_tsukimi'),
          content: '新章预告：黑猫穿过雨巷，把一封没有署名的信放在她窗台。今晚更新 3k 字，评论区可以猜结局。',
          createdAt: _ago(hours: 5),
          mood: MoodTag.love,
          circle: circle('c_doujin'),
          imageHue: 262,
          imageTitle: '雨巷黑猫',
          liked: false,
          starred: true,
          likeCount: 3,
          starCount: 2,
          commentCount: 1,
          comments: [
            Comment(
              id: 'c3',
              user: user('u_tanuki'),
              content: '我赌是青梅竹马！',
              createdAt: _ago(hours: 4),
            ),
          ],
        ),
        Post(
          id: 'p3',
          author: user('u_tanuki'),
          content: '安利一部会让人安静下来的片子。没有大招，没有反转，只有电车窗外慢慢亮起来的早晨。看完想去便利店买热可可。',
          createdAt: _ago(hours: 9),
          mood: MoodTag.fire,
          circle: circle('c_anime'),
          imageHue: 28,
          imageTitle: '晨间电车',
          liked: true,
          starred: false,
          likeCount: 2,
          starCount: 1,
          commentCount: 0,
        ),
        Post(
          id: 'p4',
          author: user(meId),
          content: '今日速写：把发卡画成了小行星环。配色还在犹豫，粉紫和薄荷青要打架，大家站哪边？',
          createdAt: _ago(days: 1, hours: 3),
          mood: MoodTag.happy,
          circle: circle('c_art'),
          imageHue: 312,
          imageTitle: '行星发卡',
          liked: false,
          starred: false,
          likeCount: 2,
          starCount: 0,
          commentCount: 1,
          comments: [
            Comment(
              id: 'c4',
              user: user('u_kaede'),
              content: '薄荷青！和你头像超配。',
              createdAt: _ago(days: 1, hours: 1),
            ),
          ],
        ),
        Post(
          id: 'p5',
          author: user('u_kaede'),
          content: '缺一个辅助，今晚十点开黑。要求：别骂队友，可以一起吃夜宵语音。掉分算我的。',
          createdAt: _ago(hours: 3, minutes: 20),
          mood: MoodTag.sleepy,
          circle: circle('c_game'),
          imageHue: 148,
          imageTitle: '夜场排队',
          liked: false,
          starred: false,
          likeCount: 1,
          starCount: 0,
          commentCount: 1,
          comments: [
            Comment(
              id: 'c5',
              user: user(meId),
              content: '我辅助很菜但很温柔，求带！',
              createdAt: _ago(hours: 3),
            ),
          ],
        ),
        Post(
          id: 'p6',
          author: user('u_nanami'),
          content: '新角色歌循环了一下午。副歌那句气口像有人轻轻拍了拍肩膀。切片已传圈子，戴耳机听。',
          createdAt: _ago(hours: 7),
          mood: MoodTag.sad,
          circle: circle('c_voice'),
          imageHue: 200,
          imageTitle: '耳机里的雨',
          liked: true,
          starred: true,
          likeCount: 4,
          starCount: 1,
          commentCount: 0,
        ),
      ];

  static List<Conversation> conversations() {
    final cv1Messages = [
      ChatMessage(id: 'm1', senderId: 'u_sakurai', text: '铃铃！下周漫展你来吗，想和你合影～', createdAt: _ago(hours: 6)),
      ChatMessage(id: 'm2', senderId: meId, text: '来！我带新画的小立牌。', createdAt: _ago(hours: 5, minutes: 50)),
      ChatMessage(id: 'm3', senderId: 'u_sakurai', text: '太好了，我在西区 Cos 舞台附近等你。', createdAt: _ago(minutes: 40)),
    ];
    final cv2Messages = [
      ChatMessage(id: 'm4', senderId: 'u_tsukimi', text: '你上次那张发卡速写，我写进新章里当信物了。', createdAt: _ago(days: 1, hours: 2)),
      ChatMessage(id: 'm5', senderId: meId, text: '哇真的吗，我要去连夜补番外！', createdAt: _ago(days: 1, hours: 1)),
    ];
    final cv3Messages = [
      ChatMessage(id: 'm6', senderId: 'u_kaede', text: '辅助位还空着哦。', createdAt: _ago(hours: 2)),
      ChatMessage(id: 'm7', senderId: 'u_kaede', text: '语音房间开好了，密码是 sakura。', createdAt: _ago(minutes: 25)),
    ];
    return [
      Conversation(
        id: 'cv1',
        peer: user('u_sakurai'),
        unread: 1,
        messages: cv1Messages,
        lastMessage: cv1Messages.last,
      ),
      Conversation(
        id: 'cv2',
        peer: user('u_tsukimi'),
        unread: 0,
        messages: cv2Messages,
        lastMessage: cv2Messages.last,
      ),
      Conversation(
        id: 'cv3',
        peer: user('u_kaede'),
        unread: 2,
        messages: cv3Messages,
        lastMessage: cv3Messages.last,
      ),
    ];
  }

  static List<Notice> notices() => [
        Notice(
          id: 'n1',
          title: '樱花祭签到成功',
          body: '连续打卡 3 天，获得徽章「樱花祭签到」。',
          createdAt: _ago(hours: 8),
          kind: 'badge',
        ),
        Notice(
          id: 'n2',
          title: '月见黑 收藏了你的动态',
          body: '「行星发卡」被收入对方的星标匣。',
          createdAt: _ago(hours: 12),
          kind: 'star',
        ),
        Notice(
          id: 'n3',
          title: '圈子邀请',
          body: '绘圈日常邀请你参加「一周配色挑战」。',
          createdAt: _ago(days: 1),
          kind: 'circle',
        ),
      ];
}
