/*1. ���q 2008DD �⦳���w�ʦ�ʤ�Ŧ�f���f�w ID Set �D�X�� */
/*2. �� 2007DD+DO ��X�L�h�f�v�P���ĥv�A�å� ID Set �L�o*/
/*3. ��X 2009 2010 2011 ����ޯe�f��(����)�A�å� ID Set �L�o�A�åB�i�H�s�@�s�����R��*/


/*1.  �i�H����򰵥X�Ӫ�����NH.Dd2008_target_patient_list(�̦n�O�@�H�@�����)
   2.  �ɹs���p�⦸�ƫܭ��n
   3.  �̦��J�|�ɶ�(for �ʦ�ʤ�Ŧ�f)�q�`���T�E�ɶ�(index date)     
        �̦��J�|�ɶ�(for ����ޯe�f��)�q�`���T�E�ɶ�(stroke date)     
        �q�`�|�ư� stroke date -index date ���t���� row   ��@���������j�ɶ�*/

libname NH 'C:\Users\Hong Guo-Peng\Desktop\SAS_demo\SAS_healthy_insurance_demo\SAS_dataset'; run;

/*2008�~�w���ʦ�ʤ�Ŧ�f(�Y�ߦٱ��)��(ICD9-CM �E�_�X�G410-414 )*/
/*��|�D�E�_�X�B���E�_�X���@�ӶE�_�X�ŦX�Һ�T�E*/
%let condition1 = substr(ICD9CM_CODE , 1 , 3)  in  ('410' '411' ' 412' '413' '414');
%let condition2 = substr(ICD9CM_CODE_1 , 1 , 3)  in  ('410' '411' ' 412' '413' '414');
%let condition3 = substr(ICD9CM_CODE_2 , 1 , 3)  in  ('410' '411' ' 412' '413' '414');
%let condition4 = substr(ICD9CM_CODE_3 , 1 , 3)  in  ('410' '411' ' 412' '413' '414');


/**macro variable �榡 ����? ->�򥻤W����r */
data _null_;
	call symput('today', year(today()));
run;
%put &today. ;

/*�~��65���ΥH�W*/
%let condition5 = %str(&today. - birth_yy >= 65);

/*��X 2008�~ �w���ʦ�ʤ�Ŧ�f���f�w*/
%macro find_patient_list; 
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
		create table NH.Dd2008_target as
		select *
		from NH.Dd2008_disease
		where (&condition1. or &condition2. or &condition3. or &condition4.) and &condition5.
	;
	quit;

	/*��ؼбw��ID��X��*/
	proc sql;
		create table NH.Dd2008_target_patient_list as
		select distinct(ID) as ID
		from NH.Dd2008_target
	;
	quit;

%mend find_patient_list; 
%find_patient_list;
		
/*��X2008�~�w���ʦ�ʤ�Ŧ�f�A�æb2009�~��o�͸���ޯe�f��*/
/*2009�~��o�͸���ޯe�f�� (ICD-9-CM�G430-437)*/
%let condition1 = substr(ICD9CM_CODE , 1 , 3)  in  ('430' '431' '432' '433' '434'  '435'  '436'  '437');        
%let condition2 = substr(ICD9CM_CODE_1 , 1 , 3)  in  ('430' '431' '432' '433' '434'  '435'  '436'  '437');
%let condition3 = substr(ICD9CM_CODE_2 , 1 , 3)  in  ('430' '431' '432' '433' '434'  '435'  '436'  '437');
%let condition4 = substr(ICD9CM_CODE_3 , 1 , 3)  in   ('430' '431' '432' '433' '434'  '435'  '436'  '437');

%macro create_after2008_stroke_dataset; 
	%do i=2009 %to 2011; 
		/*�Ы�NH.Dd_&i. ID �u���O�d2008�~���ؼЯf�w*/
		proc sql;
			create table NH.Dd_&i. as
			select ID , ICD9CM_CODE , ICD9CM_CODE_1 , ICD9CM_CODE_2 , ICD9CM_CODE_3 , IN_DATE , OUT_DATE
			from NH.Dd&i.
			where (ID in (select ID from NH.Dd2008_target_patient_list));
		quit;

		/*�c�طs��attribute stroke_&i  N_DATE_&i.  OUT_DATE_&i.�A�u�n���o�͸���ޯe�f�̡Astroke_&i=1*/	
		data NH.Dd_&i.; 
			set NH.Dd_&i.;
			if &condition1. or &condition2. or &condition3. or &condition4.  then stroke_&i. = 1;
			else stroke_&i. = 0;
			IN_DATE_&i. = IN_DATE ; 
			OUT_DATE_&i. = OUT_DATE ; 
		run;
	
		/*�u�d�UID �P stroke_&i.  N_DATE_&i.  OUT_DATE_&i.*/	
		data NH.Dd_&i. ;
			set NH.Dd_&i. (keep = ID  stroke_&i.  IN_DATE_&i.  OUT_DATE_&i.);
			if stroke_&i. = 1 then output;
		run;

		/*�⭫�Ƹ�ƧR���A�_�h�̫�left join�A��Ʒ|�V�ӶV�j*/		
		proc sort nodupkey data = NH.Dd_&i.
			out = NH.Dd_&i. ; 
			by _ALL_; 
		run;  

		/*�NNH.Dd_&i. �P Dd2008_target(�D��)�X��*/
		/*NH.Dd2008_target_2011���̲׵��G�A�]�t2009-2011�����*/	
		%if  &i. = 2009 %then %do;
			proc sql;
				create table NH.Dd2008_target_&i. as
				select a.* ,  b.stroke_&i. , b.IN_DATE_&i. , b.OUT_DATE_&i. 
				from NH.Dd2008_target as  a
				left join NH.Dd_&i. as b
				on a.ID = b.ID;
			quit;
		%end; 

		%else %if  &i. ^= 2009 %then %do;
			%let ii = %eval(&i. - 1); 
			proc sql;
				create table NH.Dd2008_target_&i. as
				select a.* ,  b.stroke_&i. , b.IN_DATE_&i. , b.OUT_DATE_&i. 
				from NH.Dd2008_target_&ii. as  a
				left join NH.Dd_&i. as b
				on a.ID = b.ID;
			quit;
	
		%end;	
	%end;	

	%do i=2009 %to 2011; 
		data NH.Dd2008_target_2011;
			set NH.Dd2008_target_2011 ;
			if stroke_&i. = . then stroke_&i. = 0;
		run;
	%end;	

	/*stroke_freq�N��2009�~��o�ͤ���������*/
	data NH.Dd2008_target_stroke;
		set NH.Dd2008_target_2011 ;
		stroke_freq = 0;   /*�֥[��l��*/
	run;
	%do i=2009 %to 2011; 
		data NH.Dd2008_target_stroke;
			set NH.Dd2008_target_stroke ;
			stroke_freq = stroke_freq + stroke_&i.;
		run;
	%end;	

	/*stroke_happen�N���L�o�͹L����*/
	data NH.Dd2008_target_stroke;
		set NH.Dd2008_target_stroke ;
		if stroke_freq >0 then stroke_happen = 1;  
		else stroke_happen = 0;        
	run;
%mend create_after2008_stroke_dataset; 
%create_after2008_stroke_dataset;


%macro after2008_stroke_percentage; 
	/*	�d�UID stroke�o���attribute*/
	data NH.Dd2008_target_stroke_happen;
		set NH.Dd2008_target_stroke (keep = ID stroke_happen);
	run;

	/*	�⭫�Ƹ�ƧR��*/
	proc sort nodupkey data = NH.Dd2008_target_stroke_happen 
		out = NH.Dd2008_target_stroke_happen ; 
		by ID  stroke_happen ; 
	run;  

	proc sort nodupkey data = NH.Dd2008_target_stroke_happen 
		out = NH.Dd2008_target_stroke_happen; 
		by ID  ; 
	run; 

	/*	�p��ؼЯf�w�H��*/	
	proc sql noprint;
		select count(distinct(ID))
		into :patient_total_num
		from NH.Dd2008_target
	;
	quit;

	/*	�p�⤤�����*/	
	proc sql;
		select sum(stroke_happen) / &patient_total_num.  as stroke_percentage 
		from NH.Dd2008_target_stroke_happen
	; 
	quit;

%mend after2008_stroke_percentage; 
%after2008_stroke_percentage;


/*	�s�����R*/	
/*	�ݭn2008�ʦ�ʤ�Ŧ�f�w�̳̦��J�|����A�P�Ӹs�H�̦���������|���*/	
%macro after2008_stroke_interval_surv; 
	%do i=2009 %to 2011; 
		%if  &i. = 2009 %then %do;
			data NH.Dd2008_target_stroke_surv ;
				set NH.Dd2008_target_stroke ;
				if IN_DATE_&i.= '' then IN_DATE_surv_&i. = '19600101' ;
				else IN_DATE_surv_&i. = IN_DATE_&i. ;
			run;
		%end; 

		%else %if  &i. ^= 2009 %then %do;
			data NH.Dd2008_target_stroke_surv ;
				set NH.Dd2008_target_stroke_surv ;
				if IN_DATE_&i.= '' then IN_DATE_surv_&i. = '19600101' ;
				else IN_DATE_surv_&i. = IN_DATE_&i. ;
			run;
		%end; 	

		data NH.Dd2008_target_stroke_surv ;
			set NH.Dd2008_target_stroke_surv ;
			interval_surv_&i. = input(IN_DATE_surv_&i. , yymmdd8.) - input(IN_DATE , yymmdd8.);
		run;

		/*interval_surv_2009 �~�����A surv_first_interval �N�O interval_surv_2009 �A�N���ݺ�2010 2011 �O���٬O�t
		   ²��ӻ��N�O��"�Ĥ@��"��������
		   �p�G�n��"�̫�@��"�������ȡA�i�H�q�᭱�M��*/	
		/*&i. = 2009 �s�Wsurv_first_interval�����A�æb interval_surv_&i. >= 0 �ɽ�ȵ�surv_first_interval*/	
		%if  &i. = 2009 %then %do;	
			data NH.Dd2008_target_stroke_surv ;
				set NH.Dd2008_target_stroke_surv ;
				if  interval_surv_&i. >= 0  then do;
					first_in_year = &i. ;
					surv_first_interval = interval_surv_&i.  ;
				end ;
			run;
		%end; 

		%else %if &i. ^= 2009 %then %do;	
			data NH.Dd2008_target_stroke_surv ;
				set NH.Dd2008_target_stroke_surv ;
				if  interval_surv_&i. >= 0 and surv_first_interval = .  then do; 
					first_in_year = &i. ;
					surv_first_interval = interval_surv_&i.  ;
			    end ;
			run;
		%end; 

	%end; 

	/*�Y�S���o�L�����A���N�H2011�~����h�̦��]��Ŧ�f��|���*/
	data NH.Dd2008_target_stroke_surv ;
		set NH.Dd2008_target_stroke_surv ;
		if  surv_first_interval = . then do; 
			surv_first_interval = input('20111231' , yymmdd8.) - input(IN_DATE , yymmdd8.) ;
	    end ;
	run;

	proc sort nodupkey data = NH.Dd2008_target_stroke_surv
		out = NH.Dd2008_target_stroke_surv ; 
		by ID surv_first_interval  ; 
	run; 

	proc sort nodupkey data = NH.Dd2008_target_stroke_surv
		out = NH.Dd2008_target_stroke_surv ; 
		by ID  ; 
	run; 	

%mend after2008_stroke_interval_surv;
%after2008_stroke_interval_surv;



/*�s�����R�ϡGKM PLOT*/
%macro km_plot_stroke_gender;
	data NH.km_plot_stroke_gender;
		set NH.Dd2008_target_stroke_surv (keep= ID_SEX  surv_first_interval  stroke_happen) ;
	run;
 
	data NH.km_plot_stroke_gender;
		set NH.km_plot_stroke_gender (rename = ( surv_first_interval  = analysis_value  )) ;
		if stroke_happen = 0 then censor = 1;
		else if stroke_happen = 1 then censor = 0;
	run;

	/*�U��ProvideSurvivalMacros*/
	data _null_;
	%let url = //support.sas.com/documentation/onlinedoc/stat/ex_code/131;
	infile "http:&url/templft.html" device=url;
	file 'macros.tmp';
	input;
	if index(_infile_, '</pre>') then stop;
	if pre then put _infile_;
	if index(_infile_, '<pre>') then pre + 1;
	run;
	%inc 'macros.tmp' / nosource;

	%ProvideSurvivalMacros
	    /*�]�w�r�j�p�B����M�r��*/
	    %let tatters = textattrs=(size=14pt weight=bold family='arial');
	    /* �ק�title */
	    %let TitleText0 = "Kaplan-Meier Plot";
	    /*�p�G���h�u���@�h��title*/
	     %let TitleText1 = &titletext0 " for " STRATUMID  / &tatters;
	    /*���h���h�h��title*/
	     %let TitleText2 = &titletext0  / &tatters;
	    /*�ٲ��Ƽ��D*/
	     %let nTitles = 1;
	    /*�ק�ϨҪ���m*/
	     %let LegendOpts = title=GROUPNAME location=inside across=1 autoalign=(TopRight);
	   /*����log rank test�W�١A��m�A�h��*/
	      %let InsetOpts = autoalign=(BottomLeft) border=false BackgroundColor=GraphWalls:Color Opaque=true;

		/*�ק�Y�b*/
	    %let yOptions = label="Survival"  labelattrs=(size=12pt weight=bold family='arial')
                linearopts=(viewmin=0.8 viewmax=1 tickvaluelist=(0.8 0.9 1.0));

	    /*�ק�s�ժ��C��B�ק�u���˦�*/
	    %let GraphOpts = DataContrastColors=(green red blue) DataColors=(green red blue)
	                                 ATTRPRIORITY=NONE DataLinePatterns=(ShortDash MediumDash LongDash);
	   /*�ק�u���ʲ�*/
	    %let StepOpts = lineattrs=(thickness=2.5);
	   /*�ק�Censor���˦�*/
	    %let Censored = markerattrs=(symbol=circlefilled size=10px);
	    %let Censorstr = "(*ESC*){Unicode '25cf'x} Censored" ;
	%CompileSurvivalTemplates

	proc format;
	   value $ID_SEX
	      "F" = "Female"
	      "M" = "Male"
	run;

	ods graphics;
	ods output survivalplot = survivalplot;
	proc lifetest data = NH.km_plot_stroke_gender  notable   plots = survival(test atrisk(maxlen=13)  atrisk=0 to 2500 by 365);
	   time analysis_value  * censor(1);  /*event���ܭn�אּ(0)*/
	   strata ID_SEX;
	run;
	%ProvideSurvivalMacros

	/* �R���w�ק諸templates. */
	proc template;
	     delete Stat.Lifetest.Graphics.ProductLimitSurvival / store=sasuser.templat;
	     delete Stat.Lifetest.Graphics.ProductLimitSurvival2 / store=sasuser.templat;
	run;

%mend km_plot_stroke_gender;
%km_plot_stroke_gender;



/*	��|�Ѽ�*/	
/*	2008�ʦ�ʤ�Ŧ�f�w�̡A���O�b 2009�B2010�B2011 �]�������Ӧ�|�Ѽƭp��*/	
%macro after2008_stroke_interval_hosp;
	%do i = 2009 %to 2011; 
		data NH.Dd2008_stroke_interval_hosp_&i.;
			set NH.Dd2008_target_stroke (keep = ID stroke_&i. IN_DATE_&i.  OUT_DATE_&i. stroke_happen);
		run;
		
 		data NH.Dd2008_stroke_interval_hosp_&i.;
			set NH.Dd2008_stroke_interval_hosp_&i.;
			if stroke_&i. = 1 and OUT_DATE_&i. and IN_DATE_&i.  then do ;
				interval_hosp = input(OUT_DATE_&i. , yymmdd8.) - input(IN_DATE_&i. , yymmdd8.);
				output;
			end;
		run;
	%end; 

%mend after2008_stroke_interval_hosp;
%after2008_stroke_interval_hosp;


proc sort data = NH.Dd2008_target
	out = NH.Dd2008_avg_age; 
	by ID; 
run;

/*�簣������ID�A�è��̫�@��*/
data NH.Dd2008_avg_age; 
	set NH.Dd2008_avg_age; 
	by ID; 
	first = first.id;
	last = last.id;
	if last= 1 then output;
run;


/*�����~��*/
proc sql;  
       select avg(age) as mean_age , std(age) as std_age
       into :patient_mean_age , :patient_std_age 
       from NH.Dd2008_avg_age ; 
quit;
%put &patient_mean_age.; 
%put &patient_std_age.; 

/*�p��f�H�`��*/
proc sql noprint;
	select count(age) as total_patient_num
	into :total_patient_num
	from NH.Dd2008_avg_age
	; 
quit;
%put &total_patient_num.; 

/*�ʧO���*/
proc sql;
	select ID_sex , count(ID_sex) / &total_patient_num. as sex_percent
	from NH.Dd2008_avg_age
	group by ID_sex
	; 
quit;



/*�w��2007�~�p��L�h�f�v���*/
/*�ؼЯe�f : ??�� ??�} ??�� �C�ʵ�Ŧ�f �C�ʪ���ʪͳ��e�f*/
%macro before_2007_disease_1; 	
	/*���Ы�macro variable  condition1_1 ~ condition5_4*/
	%do i=1 %to 5;
		/*������ (ICD9: 401-405)*/
		/*��|�D�E�_�X�B���E�_�X���@�ӶE�_�X�ŦX�Һ�T�E*/
		%if &i. = 1 %then %do;
			%let string = ('401' '402' '403' '404' '405');
		%end;

		/*����} (ICD9: 250)*/
		/*��|�D�E�_�X�B���E�_�X���@�ӶE�_�X�ŦX�Һ�T�E*/	
		%else %if &i. = 2 %then %do;
			%let string = ('250');
		%end;

		/*����� (ICD9: 272)*/
		/*��|�D�E�_�X�B���E�_�X���@�ӶE�_�X�ŦX�Һ�T�E*/
		%else %if &i. = 3 %then %do;
			%let string = ('272');
		%end;

		/*�C�ʵ�Ŧ�f (ICD9: 585)*/ 
		/*��|�D�E�_�X�B���E�_�X���@�ӶE�_�X�ŦX�Һ�T�E*/
		%else %if &i. = 4 %then %do;
			%let string = ('585');
		%end;

		/*�C�ʪ���ʪͳ��e�f (ICD9: 490-496)*/
		/*��|�D�E�_�X�B���E�_�X���@�ӶE�_�X�ŦX�Һ�T�E*/
		%else %if &i. = 5 %then %do;
			%let string = ('490' '491' ' 492' '493' '494' '495'  '496');
		%end;
		
		%do j=1 %to 4; 
			%if &j. = 1 %then %do;
				%let condition&i._&j. = substr(ICD9CM_CODE , 1 , 3) in &string.;
			%end;

			%else %if &j. ^= 1 %then %do;
				%let jj = %eval(&j. - 1); 
				%let condition&i._&j. = substr(ICD9CM_CODE_&jj. , 1 , 3) in &string.;
			%end;

			%put &i._&j. &&condition&i._&j.; 
		%end;
	%end;

	%do i=1 %to 5;
		%do j=1 %to 4; 
			%if  &i. = 1 and &j. = 1  %then %do;
				data NH.Dd2007_disease;
					set NH.Dd2007 ;
					if &&condition&i._&j. then condition_&i._&j. = 1;
					else condition_&i._&j. = 0;
				run;
			%end; 

			%else %do;
				data NH.Dd2007_disease ;
					set NH.Dd2007_disease ;
					if &&condition&i._&j. then condition_&i._&j. = 1;
					else condition_&i._&j. = 0;
				run;
			%end; 
		%end;
	%end;
%mend before_2007_disease_1; 
%before_2007_disease_1; 


%macro before_2007_disease_2; 
	/*�֥[ condition1_1 ~ condition5_4 
       1.������  2.����}  3.�����  4.�C�ʵ�Ŧ�f  5.�C�ʪ���ʪͳ��e�f 
       �u�n�����w�W�z���@�e�f�Acondition���ȳ��|�j��0 */
	data NH.Dd2007_disease;
		set NH.Dd2007_disease ;
		condition = 0 ;   /*�֥[��l��*/
	run;
	%do i=1 %to 5;	
		%do j=1 %to 4; 
				data NH.Dd2007_disease;
					set NH.Dd2007_disease ;
					condition = condition + condition_&i._&j. ;
				run;
		%end; 
	%end; 

	/*������(disease_1)  ����}(disease_2) �����(disease_3) �C�ʵ�Ŧ�f(disease_4) �C�ʪ���ʪͳ��e�f(disease_5)*/
	/*�ؼй�H�ܥi��P�ɿ��w���P�e�f�A�ҥH���ӬO�p�⿩�w�Y�دe�f���ؼЦ������ؼй�H���ʤ���*/
	%do i=1 %to 5;	
		%do j=1 %to 4; 
			%if  &j. = 1  %then %do;
				data NH.Dd2007_disease;
					set NH.Dd2007_disease ;
					disease_&i. = condition_&i._&j. ;
				run;
			%end; 

			%else %if &j. ^= 1 %then  %do;
				data NH.Dd2007_disease;
					set NH.Dd2007_disease ;
					disease_&i. = disease_&i. + condition_&i._&j. ;
				run;
			%end; 
		%end; 

		data NH.Dd2007_disease;
			set NH.Dd2007_disease ;
			if disease_&i. > 0 then disease_&i. = 1 ;
		run;
	%end; 

	/*1.������  2.����}  3.�����  4.�C�ʵ�Ŧ�f  5.�C�ʪ���ʪͳ��e�f 
        �u�n�����w�W�z���@�e�f�Acondition���ȷ|�j��0�A condition �j��0����ƿz��X�� */
	data NH.Dd2007_disease; 
		set NH.Dd2007_disease ;
		if  condition> 0 then output;
	run;

	/*�u�D��2008�~���w�ʦ�ʤ�Ŧ�f�w��*/
	proc sql;
		create table NH.Dd2007_disease as
		select * 
		from NH.Dd2007_disease
		where ID in (select ID from NH.Dd2008_target_patient_list)
		;
	quit;	

	data NH.Dd2007_disease_important; 
		set NH.Dd2007_disease (keep = ID    ICD9CM_CODE    ICD9CM_CODE_1    ICD9CM_CODE_2    ICD9CM_CODE_3    disease_1-disease_5   condition);
	run;

%mend before_2007_disease_2; 
%before_2007_disease_2; 


%macro before_2007_disease_3; 
	%do i=1 %to 5; 
		/*��P�@�ӤH���w�P�@�دe�f����ƥh����*/
		proc sort nodupkey data = NH.Dd2007_disease
			out = NH.Dd2007_disease_&i.; 
			by ID disease_&i.; 
		run;  

		/*��ID �� disease_&i. �d�U��*/	
		data NH.Dd2007_disease_&i.; 
			set NH.Dd2007_disease_&i.(keep = ID disease_&i.); 
		run; 

		/*��ID���ƪ��R�h*/		
		proc sort nodupkey data = NH.Dd2007_disease_&i.
			out = NH.Dd2007_disease_&i.; 
			by ID; 
		run;  

		/*�p��NH.Dd2007_disease_&i.���X�����*/		
		proc sql noprint;
			select count(ID) as total_disease_row_&i.
			into :  total_disease_row_&i.
			from NH.Dd2007_disease_&i.
			; 
		quit;
		%put &&total_disease_row_&i.;

		/*disease_&i.��1���`�� / NH.Dd2007_disease_&i.��Ƽ�*/			
		proc sql noprint;
			select sum(disease_&i.) / &&total_disease_row_&i.  as disease_percentage_&i.
			into :  disease_percentage_&i.
			from NH.Dd2007_disease_&i.
			; 
		quit;

	%end;	

	proc sql;
		create table Nh.disease_percentage
	    (disease char(20) , disease_percentage num);

		insert  into 
   		Nh.disease_percentage
		(disease , disease_percentage)
		values('������' ,                         &disease_percentage_1.)
		values('����}' ,                         &disease_percentage_2.)
		values('�����' ,                         &disease_percentage_3.)
		values('�C�ʵ�Ŧ�f' ,                 &disease_percentage_4.)
		values('�C�ʪ���ʪͳ��e�f' ,  &disease_percentage_5.);

		select *
		from Nh.disease_percentage
		;
	quit;

%mend before_2007_disease_3; 
%before_2007_disease_3;


/*�w��2007�~�p��L�h���ĥv���*/
/*�ؼХ��� : ANTIHYPERTENSIVES �B bblocker �B Metformin �B Statin*/
proc import file='C:\Users\Hong Guo-Peng\Desktop\SAS_demo\SAS_healthy_insurance_demo\SAS_dataset\meditation.csv' 
	out = NH.meditation
	dbms = csv replace;
run;

/*����ؼ��Ī��D�X��*/
proc sql ;
	create table NH.drug_code_group as
	select distinct drug_code , drug_group  
	from NH.meditation
	where drug_group in ('ANTIHYPERTENSIVE' , 'bblocker' , 'Metformin' , 'Statin');
quit;

proc sql; 
	create table NH.Do2007_drug as
	select a.FEE_YM , a.APPL_TYPE , a.APPL_DATE , a.CASE_TYPE , a.SEQ_NO , a.HOSP_ID , a.ORDER_CODE , 
			   b.ID , c.drug_group
	from NH.Do2007 as a

	/*left join �H���P��|��T*/		
	left join NH.Dd2007 as b
	on a.FEE_YM = b.FEE_YM and a.APPL_TYPE = b.APPL_TYPE and a.APPL_DATE = b.APPL_DATE  and a.CASE_TYPE = b.CASE_TYPE  and a.SEQ_NO = b.SEQ_NO and a.HOSP_ID = b.HOSP_ID 

	/*left join ����*/		
	left join NH.meditation as c
	on a.ORDER_CODE = c.drug_code

	/*�A��where���z�⤣�������Ī��簣*/
	where a.ORDER_CODE in (select drug_code from NH.drug_code_group) and b.ID in (select ID from NH.Dd2008_target_patient_list) 	
	;
quit;



/*ANTIHYPERTENSIVE(drug_1)  bblocker(drug_2) Metformin(drug_3) Statin(drug_4) */
/*�ؼй�H�ܥi��P�ɨϥμƺ��Ī��A�ҥH���ӬO�p��ϥθӺإ��Ī���H�������ؼй�H���ʤ���*/
data NH.Do2007_drug; 
	set NH.Do2007_drug;
	if drug_group = 'ANTIHYPERTENSIVE'  then drug_1 = 1;
	if drug_group = 'bblocker'                      then drug_2 = 1;
	if drug_group =  'Metformin'                 then drug_3 = 1;
	if drug_group = 'Statin'                          then drug_4 = 1;
run;


%macro meditation; 
	%do i=1 %to 4; 
		/*��P�@�ӤH�ΦP�@���Ī���ƥh����*/
		proc sort nodupkey data = NH.Do2007_drug
			out = NH.Do2007_drug_&i.; 
			by ID drug_&i.; 
		run;  

		/*��ID �� drug_&i. �d�U��*/	
		data NH.Do2007_drug_&i.; 
			set NH.Do2007_drug_&i. (keep = ID drug_&i.); 
		run; 

		/*��ID���ƪ��R�h*/		
		proc sort nodupkey data = NH.Do2007_drug_&i.
			out = NH.Do2007_drug_&i.; 
			by ID; 
		run;  

		/*�p��NH.Do2007_drug_&i.���X�����*/		
		proc sql noprint;
			select count(ID) as total_drug_row_&i.
			into :  total_drug_row_&i.
			from NH.Do2007_drug_&i.
			; 
		quit;
		%put &&total_drug_row_&i.;

		/*drug_&i.��1���`�� / NH.Do2007_drug_&i.��Ƽ�*/			
		proc sql noprint;
			select sum(drug_&i.) / &&total_drug_row_&i.  as drug_percentage_&i.
			into :drug_percentage_&i.
			from NH.Do2007_drug_&i.
			;
		quit;

	%end;

	proc sql;
		create table Nh.drug_percentage
	    (drug char(20) , drug_percentage num);

		insert  into 
   		Nh.drug_percentage
		(drug , drug_percentage)
		values('ANTIHYPERTENSIVE' , &drug_percentage_1.)
		values('bblocker' ,                     &drug_percentage_2.)
		values('Metformin' ,                 &drug_percentage_3.)
		values('Statin' ,                          &drug_percentage_4.);

		select *
		from Nh.drug_percentage
		;
	quit;

%mend meditation;
%meditation;
