
WITH SupplierSales AS (
    SELECT 
        S.s_suppkey,
        S.s_name,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_sales
    FROM 
        supplier S
    JOIN 
        partsupp PS ON S.s_suppkey = PS.ps_suppkey
    JOIN 
        lineitem L ON PS.ps_partkey = L.l_partkey
    WHERE 
        L.l_shipdate >= '1997-01-01'
    GROUP BY 
        S.s_suppkey, S.s_name
), 
CustomerOrders AS (
    SELECT 
        C.c_custkey,
        C.c_name,
        COUNT(O.o_orderkey) AS total_orders,
        MAX(O.o_totalprice) AS max_order_value
    FROM 
        customer C
    LEFT JOIN 
        orders O ON C.c_custkey = O.o_custkey
    GROUP BY 
        C.c_custkey, C.c_name
)
SELECT 
    R.r_name AS region,
    N.n_name AS nation,
    COALESCE(S.total_sales, 0) AS total_supplier_sales,
    COALESCE(O.total_orders, 0) AS total_customer_orders,
    MAX(O.max_order_value) AS largest_order_value
FROM 
    region R
JOIN 
    nation N ON R.r_regionkey = N.n_regionkey
LEFT JOIN 
    SupplierSales S ON N.n_nationkey = S.s_suppkey
LEFT JOIN 
    CustomerOrders O ON N.n_nationkey = O.c_custkey
WHERE 
    (O.total_orders > 0 OR S.total_sales > 0)
GROUP BY 
    R.r_name, N.n_name, S.total_sales, O.total_orders
HAVING 
    (COALESCE(S.total_sales, 0) > 50000 AND COUNT(DISTINCT S.s_suppkey) > 1)
    OR 
    (COALESCE(O.total_orders, 0) > 10)
ORDER BY 
    region, nation;
