
WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_cost
    FROM 
        supplier s
    JOIN 
        SupplierCosts sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCosts)
),
NationRegions AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
SupplierNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    hr.s_name AS high_cost_supplier,
    nr.n_name AS supplier_nation,
    hr.total_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    HighCostSuppliers hr
JOIN 
    SupplierNation nr ON hr.s_suppkey = nr.s_suppkey
LEFT JOIN 
    lineitem l ON nr.s_suppkey = l.l_suppkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'O' AND 
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    hr.s_name, nr.n_name, hr.total_cost
ORDER BY 
    total_revenue DESC;
