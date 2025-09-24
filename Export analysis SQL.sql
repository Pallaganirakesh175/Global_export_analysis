----STEPS TO BE FOLLOWED
--COMPLETED JOIN THE TABLES
--COMPLETED IMPLEMENT THE CALCULATION
--CREATE THE CTE
--CREATE THE VIEW
--ALWAYS REMEMBER FIRST TABLE STTOULD BE FACT TABLE SECOND TABLE SHOULD BE DIMENSION TABLE
--JOIN FACT TABLE WITH other DIMENTION TABLE TO GET DESCRIPTIVE INFORMATION

Create VIEW Global_Export_Analysis_VIEW AS   
with Global_Export_Analysis as
(
select 
FT.HSCode,
FT.commodity_code,
DCM.Commodity,
FT.State_Code,
DST.State_description,
FT.Supplier_Code,
DSU.supplier_description,
FT.Region_Code,
--NAMIBIA NM AND MOROCCO MOFALLS UNDER EAST AFRICA BUILD A NEW HIERARCHY
case 
	when ft.country_code in ('NM','MO') then 'EAST AFRICA' 
	ELSE DR.Region_description
end as 'New_Region_description', 
DR.Region_description,
FT.Country_Code,
DCO.Country_description,
FT.exported_to_code,
DET.EXPORTED_TO_description,
FT.Exported_Month,
DCA.Month AS Month,
DCA.Quarter AS Quarter,
DCA.Year_Month AS Year_Month,
FT.Export_Mode,
DTP.Export_Mode_Description,
FT.Material_type_code,
DMT.Material_Type,
FT.UNIT_OF_MEASURE_UOM,
Round(ft.price,2) as Price,
FT.Quantity,
FT.Freight_charges_in,
--Total sales
Round(FT.Price * ft.Quantity,2) as [Total_Sales], 

--freight charges given in percentage
ft.price * ft.quantity * (ft.freight_charges_in/100) as [Freight Charges],

--duty charges
/* QUANTITY BETWEEN 1-25 0.5% -
QUANTITY BETWEEN 26-50 -1%
QUANTITY BETWEEN 50-100 1.5% -
QUANTITY BETWEEN 100-200 - 2%
QUANTITY > 200 2.5% */
Round (ft.price * ft.quantity *  
case 
	when ft.quantity between 1 and 25 then 0.005 
	when ft.quantity between 26 and 50 then 0.001
	when ft.quantity between 51 and 100 then 0.015
	when ft.quantity between 101 and 200 then 0.02
	when ft.quantity > 200 then 0.025
	else 0
	end,2) as 'Duty_Charges'

from [dbo].[EXPO-FCT-EXPORTS ANALYSIS] FT 
LEFT outer JOIN [dbo].[DIM-COMMODITY] DCM  ON FT.commodity_code = DCM.Commodity_Code 
lEFT JOIN [dbo].[DIM-STATE] DST ON FT.State_Code = DST.State_Code 
lEFT JOIN [dbo].[DIM-SUPPLIER] DSU ON FT.Supplier_Code = DSU.Supplier_Code
lEFT JOIN [dbo].[DIM-REGION] DR ON FT.Region_Code = DR.Region_Code
lEFT JOIN [dbo].[DIM-COUNTRY] DCO ON FT.Country_Code = DCO.Country_Code
lEFT JOIN [dbo].[DIM-EXPORTED TO] DET ON FT.EXPORTED_TO_CODE = DET.EXPORTED_TO_CODE
lEFT JOIN [dbo].[DIM-CALENDAR] DCA ON FT.Exported_Month = DCA.Exported_Month
lEFT JOIN [dbo].[DIM-TRANSPORTATION] DTP ON FT.Export_Mode = DTP.Export_Mode
lEFT JOIN [dbo].[DIM-MATERIAL TYPE] DMT ON FT.Material_type_code = DMT.Material_code 
--EXCLUDE GOLD, IRON AND STEEL FROM THE ANALYSIS WHERE IT FALLS UNDER MINERAL CATEGORY
where FT.COUNTRY_CODE <> 'NM' AND DCM.commodity not in ('Gold','IRON and steel') 
)
select *,
--TOTAL COST TO COMPANY = TOTAL SALES+ FREIGHT CHARGES+DUTY CHARGES 
Round ((Total_Sales + [Freight Charges] + [Duty_Charges]),2) as 'total cost to company',
Round (total_sales - [Freight Charges] - [Duty_Charges],2) as 'Net_Sales'
from Global_Export_Analysis


SELECT * FROM Global_Export_Analysis_VIEW