class UserWorkplace
{
    final String id;
    final String userId;
    final String workplaceId;
    final bool isActive;
    
    UserWorkplace({
        required this.id,
        required this.userId,
        required this.workplaceId,
        this.isActive = true,
    });
}