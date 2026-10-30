WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SuppliersWithHighBalance AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2
    )
)
SELECT 
    r.r_name AS Region,
    n.n_name AS Nation,
    COUNT(DISTINCT c.c_custkey) AS Total_Customers,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS Total_Revenue,
    AVG(o.o_totalprice) AS Average_Order_Value
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
WHERE 
    li.l_returnflag = 'N'
    AND o.o_orderstatus IN ('F', 'P')
    AND EXISTS (
        SELECT 1 
        FROM SuppliersWithHighBalance s
        WHERE s.s_suppkey = li.l_suppkey
    )
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    Total_Revenue DESC;