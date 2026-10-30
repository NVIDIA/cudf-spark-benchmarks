WITH RecursiveOrderCTE AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY l_orderkey) as rank_val
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierCostCTE AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredCustomer AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        COALESCE(NULLIF(c.c_phone, ''), 'N/A') AS contact_number
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000
)
SELECT 
    r.r_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    (SELECT AVG(total_supply_cost) FROM SupplierCostCTE) AS avg_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    RecursiveOrderCTE o ON l.l_orderkey = o.o_orderkey
JOIN 
    FilteredCustomer c ON o.o_orderkey = c.c_custkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' AND 
    l.l_shipdate < DATE '1997-12-31'
GROUP BY 
    r.r_name
ORDER BY 
    revenue DESC;