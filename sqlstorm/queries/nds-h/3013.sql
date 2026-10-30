WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus = 'O'
),
TotalSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_partkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.s_acctbal) AS avg_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        AVG(s.s_acctbal) > 10000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    ss.part_count,
    ss.avg_balance,
    CASE 
        WHEN r.order_rank <= 5 THEN 'Top 5 Order'
        ELSE 'Regular Order'
    END AS order_category
FROM 
    RankedOrders r
LEFT JOIN 
    TotalSales ts ON r.o_orderkey = ts.ps_partkey
LEFT JOIN 
    SupplierStats ss ON ss.part_count > 0
WHERE 
    r.o_orderdate IS NOT NULL
ORDER BY 
    r.o_orderdate DESC, total_sales DESC;