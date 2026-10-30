WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'UNKNOWN'
            WHEN s.s_acctbal > 1000 THEN 'HIGH BALANCE'
            WHEN s.s_acctbal BETWEEN 500 AND 1000 THEN 'MEDIUM BALANCE'
            ELSE 'LOW BALANCE'
        END AS acctbal_category
    FROM 
        supplier s
),
PartAggregates AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_tax IS NOT NULL
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
RegionSales AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        SUM(co.total_order_value) AS total_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        CustomerOrders co ON n.n_nationkey = co.o_custkey
    GROUP BY 
        n.n_nationkey, r.r_name
)
SELECT 
    r.r_name,
    COALESCE(SUM(ps.total_available) FILTER (WHERE ps.total_available > 0), 0) AS available_parts,
    COALESCE(SUM(rs.total_sales), 0) AS region_sales,
    (SELECT COUNT(*) FROM SupplierDetails sd WHERE sd.acctbal_category = 'HIGH BALANCE') AS high_balance_suppliers
FROM 
    PartAggregates ps
JOIN 
    RegionSales rs ON ps.ps_partkey = rs.n_nationkey
JOIN 
    region r ON rs.r_name = r.r_name
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT rs.n_nationkey) > 1
ORDER BY 
    r.r_name DESC
LIMIT 10 OFFSET 5;
