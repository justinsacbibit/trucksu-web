const SignupFormSchema = {
	username: {
		field: 'text',
		type: 'text',
		placeholder: 'Username',
		defaultValue: '',
		required: true
	},
	email: {
		field: 'text',
		type: 'text',
		placeholder: 'Email',
		defaultValue: '',
		required: true,
		$email: true
	},
	password: {
		field: 'text',
		type: 'password',
		placeholder: 'Password',
		defaultValue: '',
		required: true
	},
	password_confirmation: {
		field: 'text',
		type: 'password',
		placeholder: 'Confirm Password',
		defaultValue: '',
		required: true
	}
};

export default SignupFormSchema;