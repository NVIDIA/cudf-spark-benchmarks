SELECT 
    SUP.s_name AS Supplier_Name,
    COUNT(DISTINCT O.o_orderkey) AS Total_Orders,
    SUM(L.l_extendedprice * (1 - L.l_discount)) AS Total_Sales,
    MAX(CASE WHEN L.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END) AS Return_Status,
    R.r_name AS Region_Name
FROM 
    supplier SUP
JOIN 
    partsupp PS ON SUP.s_suppkey = PS.ps_suppkey
JOIN 
    part P ON PS.ps_partkey = P.p_partkey
JOIN 
    lineitem L ON P.p_partkey = L.l_partkey
JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
JOIN 
    customer C ON O.o_custkey = C.c_custkey
JOIN 
    nation N ON SUP.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    C.c_mktsegment = 'BUILDING'
    AND L.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    SUP.s_name, R.r_name
HAVING 
    COUNT(DISTINCT O.o_orderkey) > 1
ORDER BY 
    Total_Sales DESC, Supplier_Name;