
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        C.c_name AS customer_name,
        R.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY C.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer C ON o.o_custkey = C.c_custkey
    JOIN 
        nation N ON C.c_nationkey = N.n_nationkey
    JOIN 
        region R ON N.n_regionkey = R.r_regionkey
),
HighValueOrders AS (
    SELECT 
        R.o_orderkey,
        R.o_orderdate,
        R.o_totalprice,
        R.customer_name,
        R.region_name,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_revenue,
        COUNT(L.l_orderkey) AS lineitem_count
    FROM 
        RankedOrders R
    JOIN 
        lineitem L ON R.o_orderkey = L.l_orderkey
    WHERE 
        R.rank <= 5
    GROUP BY 
        R.o_orderkey, R.o_orderdate, R.o_totalprice, R.customer_name, R.region_name
)
SELECT 
    h.customer_name,
    h.region_name,
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    h.total_revenue,
    h.lineitem_count
FROM 
    HighValueOrders h
WHERE 
    h.total_revenue > 10000
ORDER BY 
    h.total_revenue DESC;
