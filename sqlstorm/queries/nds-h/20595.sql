WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
TotalSales AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
MaxTotalPrice AS (
    SELECT 
        MAX(o_totalprice) AS max_price 
    FROM 
        RankedOrders 
    WHERE 
        rnk <= 5
),
OuterJoinExample AS (
    SELECT 
        n.n_name, 
        COALESCE(tp.total_revenue, 0) AS total_revenue,
        COALESCE(sp.supplier_value, 0) AS supplier_value
    FROM 
        nation n 
    LEFT OUTER JOIN TotalSales tp ON n.n_name = tp.n_name
    LEFT OUTER JOIN SupplierParts sp ON n.n_nationkey = sp.s_suppkey 
    WHERE 
        n.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE 'E%')
)
SELECT 
    oj.n_name,
    oj.total_revenue,
    oj.supplier_value,
    (oj.total_revenue - oj.supplier_value) AS profit,
    CASE 
        WHEN oj.total_revenue IS NULL THEN 'No Revenue'
        WHEN oj.supplier_value IS NULL THEN 'No Supplier Value'
        ELSE 'Normal'
    END AS revenue_status
FROM 
    OuterJoinExample oj
WHERE 
    (oj.total_revenue IS NOT NULL OR oj.supplier_value IS NOT NULL)
    AND (oj.total_revenue <> 0 OR oj.supplier_value <> 0)
ORDER BY 
    revenue_status DESC, 
    profit DESC
LIMIT 10;