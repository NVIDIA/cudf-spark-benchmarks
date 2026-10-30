SELECT 
    P.p_name AS Part_Name,
    S.s_name AS Supplier_Name,
    C.c_name AS Customer_Name,
    O.o_orderkey AS Order_Key,
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS Total_Sales,
    AVG(L.l_quantity) AS Average_Quantity,
    COUNT(DISTINCT O.o_orderkey) AS Order_Count,
    P.p_type AS Part_Type,
    R.r_name AS Region_Name
FROM 
    part P
JOIN 
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN 
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN 
    lineitem L ON P.p_partkey = L.l_partkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    customer C ON O.o_custkey = C.c_custkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    L.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND C.c_mktsegment = 'BUILDING'
GROUP BY 
    P.p_name, S.s_name, C.c_name, O.o_orderkey, P.p_type, R.r_name
HAVING 
    SUM(L.l_extendedprice * (1 - L.l_discount)) > 1000
ORDER BY 
    Total_Sales DESC, Part_Name;