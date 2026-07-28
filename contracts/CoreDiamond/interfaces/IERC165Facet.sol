// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IERC165Facet {

		function supportsInterface(bytes4 interfaceId)
			external
			view
			returns (bool);

		function registerInterface(bytes4 interfaceId) external;

		function removeInterface(bytes4 interfaceId) external;
	}