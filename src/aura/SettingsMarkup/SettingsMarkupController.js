({
    handleEditClick: function(cmp, event, helper){
        var isEdit = cmp.get('v.isEdit');
        cmp.set('v.isEdit', !isEdit);
    }
});