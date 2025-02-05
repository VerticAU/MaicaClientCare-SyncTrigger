({
    submit: function (cmp, helper) {
        return helper.execute(
            cmp,
            'SettingsSyncSubmitProc',
            cmp.get('v.meta.dto'),
            function (response) {
                cmp.find('notifLib').showToast({
                    variant: 'success',
                    message: 'The Setting was saved.'
                });
                return Promise.resolve(response);
            },
            function (errors) {
                cmp.find('notifLib').showToast({
                    variant: 'error',
                    message: 'Please, review the errors.'
                });
                cmp.showErrors(errors);
                return Promise.reject(errors);
            }
        );
    },

    init: function (cmp) {
        return cmp.doInit({});
    }
});