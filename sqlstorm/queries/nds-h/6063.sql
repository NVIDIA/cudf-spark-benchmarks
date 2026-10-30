WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
OrderSummary AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    rs.region_name,
    os.total_orders,
    os.order_count,
    ps.total_avail_qty,
    ps.avg_supply_cost,
    rs.total_supplier_balance 
FROM 
    RegionStats rs
LEFT JOIN 
    OrderSummary os ON os.c_nationkey = rs.nation_count
LEFT JOIN 
    PartSupplierStats ps ON ps.ps_partkey = 
        (SELECT p.p_partkey 
         FROM part p 
         ORDER BY p.p_retailprice DESC 
         LIMIT 1)
WHERE 
    rs.total_supplier_balance > 10000
ORDER BY 
    rs.total_supplier_balance DESC, os.total_orders DESC;
