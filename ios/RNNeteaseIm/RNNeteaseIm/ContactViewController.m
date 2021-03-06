//
//  ContactViewController.m
//  NIM
//
//  Created by Dowin on 2017/5/2.
//  Copyright © 2017年 Dowin. All rights reserved.
//

#import "ContactViewController.h"
#import "NTESGroupedContacts.h"
#import "NTESContactDataMember.h"
//#import "NIMContactSelectViewController.h"
#import "NTESBundleSetting.h"
@interface ContactViewController ()<NIMLoginManagerDelegate,NIMSystemNotificationManagerDelegate,NIMUserManagerDelegate>
{
  NTESContactDataMember *_contacts;
    NSMutableOrderedSet *_specialGroupTtiles;
    NSMutableOrderedSet *_specialGroups;
    NSMutableOrderedSet *_groupTtiles;
    NSMutableOrderedSet *_groups;
    NIMUser            *_user;
    NSArray *notifications;
}
@end

@implementation ContactViewController
+(instancetype)initWithContactViewController{
    static ContactViewController *nimAddVC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nimAddVC = [[ContactViewController alloc]init];
        [nimAddVC initWithDelegate];
    
    });
    return nimAddVC;
}
-(void)initWithDelegate{
    [[[NIMSDK sharedSDK] loginManager] addDelegate:self];
    _specialGroupTtiles = [[NSMutableOrderedSet alloc] init];
    _specialGroups = [[NSMutableOrderedSet alloc] init];
    _groupTtiles = [[NSMutableOrderedSet alloc] init];
    _groups = [[NSMutableOrderedSet alloc] init];
    [[[NIMSDK sharedSDK] systemNotificationManager] addDelegate:self];
    [[[NIMSDK sharedSDK] userManager] addDelegate:self];
    
    id<NIMSystemNotificationManager> systemNotificationManager = [[NIMSDK sharedSDK] systemNotificationManager];
    [systemNotificationManager addDelegate:self];
    notifications = [systemNotificationManager fetchSystemNotifications:nil limit:20];
}

- (void)disealloc{
    [[[NIMSDK sharedSDK] loginManager] removeDelegate:self];
}
-(void)getFriendList:(Success )success error:(Error )error{
    NSMutableArray *contacts = [NSMutableArray array];
    for (NIMUser *user in [NIMSDK sharedSDK].userManager.myFriends) {
        NIMKitInfo *info           = [[NIMKit sharedKit] infoByUser:user.userId option:nil];
        _contacts = [[NTESContactDataMember alloc] init];
        _contacts.info               = info;
        [contacts addObject:_contacts];
    }
    NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
    NSString *me = [[NIMSDK sharedSDK].loginManager currentAccount];
    for (id<NTESGroupMemberProtocol>member in contacts) {
        if ([[member memberId] isEqualToString:me]) {
            continue;
        }
        if ([member memberId].length == 5) {
            continue;
        }
        NSString *groupTitle = [member groupTitle];
        NTESContactDataMember *contact  =member;
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:[NSString stringWithFormat:@"%@", contact.info.showName] forKey:@"name"];
        [dic setObject:[NSString stringWithFormat:@"%@", contact.info.infoId] forKey:@"contactId"];
        if (contact.info.avatarUrlString.length != 0) {
            [dic setObject:[NSString stringWithFormat:@"%@", contact.info.avatarUrlString ] forKey:@"avatar"];
        }else{
            [dic setObject:@""forKey:@"avatar"];
        }
        
        NSMutableArray *groupedMembers = [tmp objectForKey:groupTitle];
        if(!groupedMembers) {
            groupedMembers = [NSMutableArray array];
        }
        [groupedMembers addObject:dic];
        [tmp setObject:groupedMembers forKey:groupTitle];
    }
    if (tmp) {
        success(tmp);
    }else{
        error(@"网络错误");
    }
}
-(void)getAllContactFriends{
    
    NSMutableArray *contacts = [NSMutableArray array];
    for (NIMUser *user in [NIMSDK sharedSDK].userManager.myFriends) {
        NIMKitInfo *info           = [[NIMKit sharedKit] infoByUser:user.userId option:nil];
        _contacts = [[NTESContactDataMember alloc] init];
        _contacts.info               = info;
        [contacts addObject:_contacts];
    }
    [self setMembers:contacts];
}
//获取本地用户资料
-(void)getUserInFo:(NSString *)userId Success:(Success )success{
    NIMUser   *user = [[NIMSDK sharedSDK].userManager userInfo:userId];
    BOOL isMe          = [userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount];
    BOOL isMyFriend    = [[NIMSDK sharedSDK].userManager isMyFriend:userId];
    BOOL isInBlackList = [[NIMSDK sharedSDK].userManager isUserInBlackList:userId];
    BOOL needNotify    = [[NIMSDK sharedSDK].userManager notifyForNewMsg:userId];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setObject:[NSString stringWithFormat:@"%@", user.userId] forKey:@"contactId"];
    [dic setObject:[NSString stringWithFormat:@"%@", user.alias] forKey:@"alias"];
    [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.nickName] forKey:@"name"];
    [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.avatarUrl] forKey:@"avatar"];
    [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.sign] forKey:@"signature"];
    [dic setObject:[NSString stringWithFormat:@"%ld", user.userInfo.gender ] forKey:@"gender"];
    [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.email] forKey:@"email"];
    [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.birth] forKey:@"birthday"];
    [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.mobile] forKey:@"mobile"];
    [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.ext] forKey:@"extension"];
    [dic setObject:[NSString stringWithFormat:@"%d",isMe] forKey:@"isMe"];
    [dic setObject:[NSString stringWithFormat:@"%d",isMyFriend] forKey:@"isMyFriend"];
    [dic setObject:[NSString stringWithFormat:@"%d",isInBlackList] forKey:@"isInBlackList"];
    [dic setObject:[NSString stringWithFormat:@"%d",needNotify] forKey:@"mute"];
    [dic setObject:@"" forKey:@"extensionMap"];
    NSArray *keys = [dic allKeys];
    for (NSString *tem  in keys) {
        if ([[dic objectForKey:tem] isEqualToString:@"(null)"]) {
            [dic setObject:@"" forKey:tem];
        }
    }
    success(dic);
}

//获取服务器用户资料
-(void)fetchUserInfos:(NSString *)userId Success:(Success )success error:(Error )err{
    [[NIMSDK sharedSDK].userManager fetchUserInfos:@[userId] completion:^(NSArray *users, NSError *error) {
        if (users.count) {
            BOOL isMe          = [userId isEqualToString:[NIMSDK sharedSDK].loginManager.currentAccount];
            BOOL isMyFriend    = [[NIMSDK sharedSDK].userManager isMyFriend:userId];
            BOOL isInBlackList = [[NIMSDK sharedSDK].userManager isUserInBlackList:userId];
            BOOL needNotify    = [[NIMSDK sharedSDK].userManager notifyForNewMsg:userId];
            for (NIMUser   *user in users) {
                NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                [dic setObject:[NSString stringWithFormat:@"%@", user.userId] forKey:@"contactId"];
                [dic setObject:[NSString stringWithFormat:@"%@", user.alias] forKey:@"alias"];
                [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.nickName] forKey:@"name"];
                [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.avatarUrl] forKey:@"avatar"];
                [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.sign] forKey:@"signature"];
                [dic setObject:[NSString stringWithFormat:@"%ld", user.userInfo.gender ] forKey:@"gender"];
                [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.email] forKey:@"email"];
                [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.birth] forKey:@"birthday"];
                [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.mobile] forKey:@"mobile"];
                [dic setObject:[NSString stringWithFormat:@"%@",user.userInfo.ext] forKey:@"extension"];
                [dic setObject:@"" forKey:@"extensionMap"];
                [dic setObject:[NSString stringWithFormat:@"%d",isMe] forKey:@"isMe"];
                [dic setObject:[NSString stringWithFormat:@"%d",isMyFriend] forKey:@"isMyFriend"];
                [dic setObject:[NSString stringWithFormat:@"%d",isInBlackList] forKey:@"isInBlackList"];
                [dic setObject:[NSString stringWithFormat:@"%d",needNotify] forKey:@"needNotify"];
                NSArray *keys = [dic allKeys];
                for (NSString *tem  in keys) {
                    if ([[dic objectForKey:tem] isEqualToString:@"(null)"]) {
                        [dic setObject:@"" forKey:tem];
                    }
                }
                success(dic);
            }
        }else{
            err(@"该用户不存在,请检查你输入的帐号是否正确");
        }
    }];

}
//修改好友备注
-(void)upDateUserInfo:(NSString *)contactId alias:(NSString *)alias Success:(Success )success error:(Error )err{
    _user = [[NIMSDK sharedSDK].userManager userInfo:contactId];
    _user.alias = alias;
    [[NIMSDK sharedSDK].userManager updateUser:_user completion:^(NSError *error) {
        if (!error) {
            success(@"200");
        }else{
            err(@"备注名设置失败，请重试");
        }
    }];

}
//修改个人资料
-(void)updateMyUserInfo:(NSDictionary *)userInFo Success:(Success )success error:(Error )err{
    NSArray *keys = [userInFo allKeys];
    NSMutableDictionary  *userDic;
    for (NSString *tem  in keys) {
        //设置用户昵称
        if ([[userInFo objectForKey:tem] isEqualToString:@"NIMUserInfoUpdateTagNick"]) {
            [userDic setObject:@(NIMUserInfoUpdateTagNick) forKey:[userInFo objectForKey:@"NIMUserInfoUpdateTagNick"]];
        }
        //用户头像
        if ([[userInFo objectForKey:tem] isEqualToString:@"NIMUserInfoUpdateTagAvatar"]) {
            [userDic setObject:@(NIMUserInfoUpdateTagAvatar) forKey:[userInFo objectForKey:@"NIMUserInfoUpdateTagAvatar"]];
        }
        //用户签名
        if ([[userInFo objectForKey:tem] isEqualToString:@"NIMUserInfoUpdateTagSign"]) {
            [userDic setObject:@(NIMUserInfoUpdateTagSign) forKey:[userInFo objectForKey:@"NIMUserInfoUpdateTagSign"]];
        }
        //用户性别
        if ([[userInFo objectForKey:tem] isEqualToString:@"NIMUserInfoUpdateTagGender"]) {
            [userDic setObject:@(NIMUserInfoUpdateTagGender) forKey:[userInFo objectForKey:@"NIMUserInfoUpdateTagGender"]];
        }
        //用户邮箱
        if ([[userInFo objectForKey:tem] isEqualToString:@"NIMUserInfoUpdateTagEmail"]) {
            [userDic setObject:@(NIMUserInfoUpdateTagEmail) forKey:[userInFo objectForKey:@"NIMUserInfoUpdateTagEmail"]];
        }
        //用户生日
        if ([[userInFo objectForKey:tem] isEqualToString:@"NIMUserInfoUpdateTagBirth"]) {
            [userDic setObject:@(NIMUserInfoUpdateTagBirth) forKey:[userInFo objectForKey:@"NIMUserInfoUpdateTagBirth"]];
        }
        //用户手机
        if ([[userInFo objectForKey:tem] isEqualToString:@"NIMUserInfoUpdateTagBirth"]) {
            [userDic setObject:@(NIMUserInfoUpdateTagBirth) forKey:[userInFo objectForKey:@"NIMUserInfoUpdateTagBirth"]];
        }
        //拓展字段
        if ([[userInFo objectForKey:tem] isEqualToString:@"NIMUserInfoUpdateTagExt"]) {
            [userDic setObject:@(NIMUserInfoUpdateTagExt) forKey:[userInFo objectForKey:@"NIMUserInfoUpdateTagExt"]];
        }
        
    }
    
    
    [[NIMSDK sharedSDK].userManager updateMyUserInfo:userDic completion:^(NSError *error) {
        if (!error) {
            success(@"设置成功");
        }else{
            err(@"昵称设置失败，请重试");
        }
    }];

}
//- (void)presentMemberSelector:(ContactSelectFinishBlock) block{
//    NSMutableArray *users = [[NSMutableArray alloc] init];
//    //使用内置的好友选择器
//    NIMContactFriendSelectConfig *config = [[NIMContactFriendSelectConfig alloc] init];
//    //获取自己id
//    NSString *currentUserId = [[NIMSDK sharedSDK].loginManager currentAccount];
//    [users addObject:currentUserId];
//    //将自己的id过滤
//    config.filterIds = users;
//    //需要多选
//    config.needMutiSelected = YES;
//    //初始化联系人选择器
//    NIMContactSelectViewController *vc = [[NIMContactSelectViewController alloc] initWithConfig:config];
//    //回调处理
//    vc.finshBlock = block;
//    [vc show];
//}

//获取通讯录列表
- (void)setMembers:(NSArray *)members
{
    NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
    NSString *me = [[NIMSDK sharedSDK].loginManager currentAccount];
 
    for (id<NTESGroupMemberProtocol>member in members) {
        if ([[member memberId] isEqualToString:me]) {
            continue;
        }
        NSString *groupTitle = [member groupTitle];
        NTESContactDataMember *contact  =member;
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:[NSString stringWithFormat:@"%@", contact.info.showName] forKey:@"name"];
        [dic setObject:[NSString stringWithFormat:@"%@", contact.info.infoId] forKey:@"contactId"];
        if (contact.info.avatarUrlString.length != 0) {
            [dic setObject:[NSString stringWithFormat:@"%@", contact.info.avatarUrlString ] forKey:@"avatar"];
        }else{
        [dic setObject:@""forKey:@"avatar"];
        }
        
        NSMutableArray *groupedMembers = [tmp objectForKey:groupTitle];
        if(!groupedMembers) {
            groupedMembers = [NSMutableArray array];
        }
        [groupedMembers addObject:dic];
        [tmp setObject:groupedMembers forKey:groupTitle];
    }

    NIMModel *model = [NIMModel initShareMD];
    model.contactList = tmp;
}

//通讯录删除好友
-(void)deleteFriends:(NSString *)userId Success:(Success )success error:(Error )err{
    [[NIMSDK sharedSDK].userManager deleteFriend:userId completion:^(NSError *error) {
        if (!error) {
            for (NIMSystemNotification *noti in notifications) {
                if ([userId isEqualToString:noti.sourceID]) {
                    [[[NIMSDK sharedSDK] systemNotificationManager] deleteNotification:noti];
                }
            }
            success(@"200");
        }else{
            err(@"删除失败");
        }
    }];

}
//添加好友
-(void)adduserId:(NSString *)userId andVerifyType:(NSString *)strType andMag:(NSString *)msg Friends:(Error)err  Success:(Error )success{
    __weak typeof(self)weakSelf = self;
    NIMUserRequest *request = [[NIMUserRequest alloc] init];
    request.userId = userId;
    request.message = msg;
    NSInteger type = [strType integerValue];
    request.operation = (type == 1)?NIMUserOperationAdd:NIMUserOperationRequest;
    NSString *apnsText = (type == 1)?@"添加你为好友":@"请求加为好友";
    NSString *successText = request.operation == NIMUserOperationAdd ? @"添加成功" : @"请求成功";
    NSString *failedText =  request.operation == NIMUserOperationAdd ? @"添加失败" : @"请求失败";
    NSString *myID = [NIMSDK sharedSDK].loginManager.currentAccount;
    NIMUser *user = [[NIMSDK sharedSDK].userManager userInfo:myID];
    NSString *apnsContent = [NSString stringWithFormat:@"%@ %@",user.userInfo.nickName,apnsText];
    NSDictionary *dataDict = @{@"type":@"1",@"data":@{@"content":msg}};
        [[NIMSDK sharedSDK].userManager requestFriend:request completion:^(NSError *error) {
            if (!error) {
                success(successText);
                [weakSelf sendCustomNotificationContent:msg andSessionID:userId andApnsContent:apnsContent AndData:dataDict];
               // [self refresh];
            }else{
                err(failedText);
            }
        }];
}
//发送自定义通知
- (void)sendCustomNotificationContent:(NSString *)content andSessionID:(NSString *)sessionID andApnsContent:(NSString *)strApns AndData:(NSDictionary *)dict{
    NIMSession *session = [NIMSession session:sessionID type:NIMSessionTypeP2P];
    NIMCustomSystemNotification *notifi = [[NIMCustomSystemNotification alloc]initWithContent:content];
    notifi.apnsContent = strApns;
    notifi.apnsPayload = dict;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notifi toSession:session completion:nil];//发送自定义通知
}

- (void)onLogin:(NIMLoginStep)step
{
    if (step == NIMLoginStepSyncOK) {
        if (self.isViewLoaded) {//没有加载view的话viewDidLoad里会走一遍prepareData
            [self refresh];
        }
    }
}

#pragma mark - NIMSDK Delegate
- (void)onSystemNotificationCountChanged:(NSInteger)unreadCount
{
    NIMModel *mode = [NIMModel initShareMD];
    mode.unreadCount = unreadCount;
}


- (void)onUserInfoChanged:(NIMUser *)user
{
    [self refresh];
}

- (void)onFriendChanged:(NIMUser *)user{
    [self refresh];
}

- (void)onBlackListChanged
{
    [self refresh];
}

- (void)onMuteListChanged
{
    [self refresh];
}

- (void)refresh
{
[self getAllContactFriends];
}


@end
