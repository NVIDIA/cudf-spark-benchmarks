
WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice) AS line_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ss.s_name,
    nr.region_name,
    os.o_orderkey,
    os.o_totalprice,
    os.line_total,
    CASE 
        WHEN os.line_total IS NULL THEN 'No Lines'
        ELSE 'Has Lines'
    END AS line_status,
    COALESCE(ss.total_available_quantity, 0) AS total_available_quantity,
    COALESCE(ss.total_cost, 0) AS total_cost
FROM 
    SupplierSummary ss
FULL OUTER JOIN 
    NationRegion nr ON ss.s_suppkey = nr.n_nationkey
LEFT JOIN 
    OrderDetails os ON ss.s_suppkey = os.o_orderkey
WHERE 
    (COALESCE(ss.total_available_quantity, 0) > 100 OR nr.region_name IS NOT NULL)
    AND COALESCE(ss.total_cost, 0) IS NOT NULL
ORDER BY 
    nr.region_name DESC, 
    ss.total_cost ASC;
