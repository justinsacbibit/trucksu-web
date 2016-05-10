import _ from 'lodash';
import React from 'react';

import Fields from './fields';

const Form = React.createClass({
	getDefaultProps() {
		return {
			schema: {}
		};
	},
	getInitialState() {
		return {
			value: {}
		};
	},
	changeHandler(e) {
		var value = this.state.value;

		value[e.target.name] = e.target.value;
		this.setState({
			value: value
		});
	},
	getValue() {
		return this.state.value;
	},
	render() {
		const fields = _.reduce(this.props.schema, (result, field, key) => {
			let element = Fields[field.field];

			if(element) {
				let props = {
					...field,
					name: key,
					value: this.state.value[key],
					onChange: this.changeHandler
				};

				result.push(
					<div className='field' key={`field_${key}`}>
						{ React.createElement(element, props) }
					</div>
				);
			}
			return result;
		}, []);

		return (
			<div className='form'>
				{ fields }
			</div>
		);
	}
});

export default Form;