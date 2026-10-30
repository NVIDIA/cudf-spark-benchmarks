WITH SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name
),
PartSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_partkey
),
RankedSuppliers AS (
    SELECT 
        sc.ps_partkey,
        sc.s_name,
        sc.total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY sc.ps_partkey ORDER BY sc.total_supply_cost DESC) AS rank
    FROM 
        SupplierCost sc
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_sales, 0) AS total_sales,
    COALESCE(rs.total_supply_cost, 0) AS total_supply_cost,
    rs.s_name AS top_supplier
FROM 
    part p
LEFT JOIN 
    PartSales ps ON p.p_partkey = ps.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey AND rs.rank = 1
WHERE 
    p.p_size > 10
    AND (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'N') > 5
ORDER BY 
    total_sales DESC, total_supply_cost ASC;