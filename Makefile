# Copyright Erlware, LLC. All Rights Reserved.
#
# This file is provided to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file
# except in compliance with the License.  You may obtain
# a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
IEXFLAGS= -pa $(CURDIR)/.eunit -pa $(CURDIR)/ebin -pa $(CURDIR)/deps/*/ebin

IEX = $(shell which iex)
ifeq ($(IEX),)
$(error "iex not available on this system")
endif

MIX=$(shell which mix)

ifeq ($(MIX),)
$(error "Mix not available on this system")
endif

.PHONY: all compile clean test dialyzer update-deps shell

all: deps compile

# =============================================================================
# Rules to build the system
# =============================================================================

deps:
	$(MIX) deps.get

update-deps:
	$(MIX) deps.update

compile: deps
	$(MIX) compile

test: compile
	$(MIX) test

dialyzer: test
	$(MIX) dialyzer.plt
	$(MIX) dialyzer


shell: compile
# You often want *rebuilt* rebar tests to be available to the
# shell you have to call eunit (to get the tests
# rebuilt). However, eunit runs the tests, which probably
# fails (thats probably why You want them in the shell). This
# runs eunit but tells make to ignore the result.
	- @$(MIX) test
	@$(IEX) $(IEXFLAGS)

pdf:
	pandoc README.md -o README.pdf

clean:
	$(MIX) clean

distclean: clean
	$(MIX) deps.clean


rebuild: distclean deps compile dialyzer test
