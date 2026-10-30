WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) as rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopOrderDetails AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        SUM(li.l_quantity) AS total_items,
        COUNT(DISTINCT li.l_partkey) AS unique_parts
    FROM 
        RankedOrders ro
    JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE 
        ro.rank <= 10
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    tos.o_orderkey,
    tos.o_orderdate,
    tos.o_totalprice,
    tos.total_items,
    tos.unique_parts,
    ss.s_name,
    ss.revenue
FROM 
    TopOrderDetails tos
JOIN 
    SupplierSales ss ON tos.unique_parts > (SELECT AVG(unique_parts) FROM TopOrderDetails)
ORDER BY 
    tos.o_totalprice DESC, ss.revenue DESC
LIMIT 50;