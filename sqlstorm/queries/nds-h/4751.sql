WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey, 
        r.r_name AS region_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        r.r_name
),
PriceStatistics AS (
    SELECT 
        l.l_partkey, 
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price, 
        COUNT(*) AS order_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(sd.total_supply_cost, 0) AS total_supply_cost,
    cr.total_spent,
    ps.avg_price,
    ps.order_count
FROM 
    part p
LEFT JOIN 
    SupplierDetails sd ON p.p_partkey = sd.s_nationkey
LEFT JOIN 
    CustomerRegions cr ON cr.c_custkey = sd.s_suppkey
LEFT JOIN 
    PriceStatistics ps ON ps.l_partkey = p.p_partkey
WHERE 
    (cr.total_spent IS NULL OR cr.total_spent > 1000)
    AND (sd.total_supply_cost IS NOT NULL OR ps.avg_price IS NULL)
ORDER BY 
    total_supply_cost DESC, 
    cr.total_spent DESC;