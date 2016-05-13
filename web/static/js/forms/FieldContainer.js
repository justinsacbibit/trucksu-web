import React from 'react';

const FieldContainer = React.createClass({
	render() {
		const { field, fieldProps, errors } = this.props;
		return <div className={`field${errors ? ' invalid' : ''}`} key={`field_${fieldProps.name}`}>
			{ React.createElement(field, fieldProps) }
			<div className='error'>{ errors }</div>
		</div>;
	}
});

export default FieldContainer;