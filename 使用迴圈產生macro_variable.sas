libname NH 'C:\Users\Hong Guo-Peng\Desktop\SAS_demo\SAS_healthy_insurance_demo\SAS_dataset'; run;

/*macro variable 格式 怎麼看? ->基本上都文字 */
data _null_;
	call symput('today', year(today()));
run;
%put &today. ;

%let condition5 = %str(&today. - birth_yy >= 65);

/*way 1 */
data NH.test;
	length condition_ $ 6000;
	retain condition_ ;
	do i =1 to 4 ;
		if i = 1 then do;
			condition_ = catx(' or ' , condition_ , 
                                            "substr(ICD9CM_CODE , 1 , 3)  in  ('410' '411' ' 412' '413' '414')");
		end;

		else if i ^= 1 then do; 
			a = "substr(ICD9CM_CODE_" ;
			b = put(i-1 , $1.) ;
			c = ", 1 , 3) in ('410' '411' ' 412' '413' '414')" ;
			condition_ = catx(' or ' , condition_ ,  cat( a  ,  b  ,  c ));
	   	end;		
		output;

	end;
	
	call symput('condition' , condition_);
	proc print;
run;

%put &condition.;

%macro makesets; 
	proc sql;
		create table NH.Dd2008_disease as
		select FEE_YM , APPL_TYPE , HOSP_ID  ,  APPL_DATE ,  CASE_TYPE ,  CASE_TYPE ,  ID , ID_BIRTHDAY ,  IN_DATE ,  ICD9CM_CODE , ICD9CM_CODE_1 , ICD9CM_CODE_2 ,  ICD9CM_CODE_3 , ID_SEX ,
	                INPUT(substr(ID_BIRTHDAY , 1 , 4) , 4.) as birth_yy , INPUT(substr(ID_BIRTHDAY , 5 , 2) , 2.) as birth_mm
		from NH.Dd2008
	;
	quit;

	proc sql;
		create table NH.Dd2008_disease as
		select * , &today. - birth_yy as age
		from NH.Dd2008_disease
	;
	quit;

	proc sql;
		create table NH.test as
		select *
		from NH.Dd2008_disease
		where &condition. and &condition5.
	;
	quit;

	/*把目標患者ID找出來*/
	proc sql;
		create table NH.test_ as
		select distinct(ID) as ID
		from NH.test
	;
	quit;

%mend makesets; 
%makesets;


libname NH 'C:\Users\Hong Guo-Peng\Desktop\SAS_demo\SAS_healthy_insurance_demo\SAS_dataset'; run;


/*macro variable 格式 怎麼看? ->基本上都文字 */
data _null_;
	call symput('today', year(today()));
run;
%put &today. ;

%let condition5 = %str(&today. - birth_yy >= 65);


/*way 2 */
%macro makesets; 

	%do i=1 %to 1; 
		%do j=1 %to 4; 
			%let i_j = %eval(4*(&i. - 1) + &j.); 
			%let string = ('410' '411' ' 412' '413' '414');

			%if &j. = 1 %then %do;
				%let condition&i_j. = substr(ICD9CM_CODE , 1 , 3) in &string.;
			%end;

			%else %if &j. ^= 1 %then %do;
				%let jj = %eval(&j. - 1); 
				%let condition&i_j. = substr(ICD9CM_CODE_&jj. , 1 , 3) in &string.;
			%end;

			%put &&condition&i_j.; 
		%end;
	%end;

	/*For 2008 患有缺血性心臟病的病患找出來*/	
    proc sql;
		create table NH.Dd2008_disease as
		select FEE_YM , APPL_TYPE , HOSP_ID  ,  APPL_DATE ,  CASE_TYPE ,  CASE_TYPE ,  ID , ID_BIRTHDAY ,  IN_DATE ,  ICD9CM_CODE , ICD9CM_CODE_1 , ICD9CM_CODE_2 ,  ICD9CM_CODE_3 , ID_SEX ,
	                INPUT(substr(ID_BIRTHDAY , 1 , 4) , 4.) as birth_yy , INPUT(substr(ID_BIRTHDAY , 5 , 2) , 2.) as birth_mm
		from NH.Dd2008
	;
	quit;

	proc sql;
		create table NH.Dd2008_disease as
		select * , &today. - birth_yy as age
		from NH.Dd2008_disease
	;
	quit;

	%do i=1 %to 4; 
		%if  &i. = 1 %then %do;
			data NH.test;
				set NH.Dd2008_disease ;
				if &&condition&i. then condition_&i. = 1;
				else condition_&i. = 0;
				condition = condition_&i.;
			run;
		%end; 

		%else %if  &i. ^= 1  %then %do;
			%let ii = %eval(&i. - 1);
			data NH.test;
				set NH.test (drop = condition_&ii.);
				if &&condition&i. then condition_&i. = 1;
				else condition_&i. = 0;
				condition = condition + condition_&i. ;
			run;
		%end; 
	%end;	

	data NH.test (drop = condition_4); 
		set NH.test ;
		if &condition5. or condition> 0 then output;
	run;

	/*把目標患者ID找出來*/
	proc sql;
		create table NH.test_ as
		select distinct(ID) as ID
		from NH.test
	;
	
	quit;
		
%mend makesets; 
%makesets;

;*';*";*/quit;run;
