WITH SupplyCostDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        (o.o_totalprice - COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0)) AS net_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' 
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
),
RegionalPerformance AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value,
        SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_net_sales
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    rp.nation_name,
    rp.region_name,
    rp.total_orders,
    rp.avg_order_value,
    rp.total_net_sales,
    scd.s_name,
    scd.p_name,
    scd.ps_availqty,
    scd.total_supply_cost
FROM 
    RegionalPerformance rp
JOIN 
    SupplyCostDetails scd ON rp.total_orders > 1000
ORDER BY 
    rp.total_net_sales DESC, 
    scd.total_supply_cost ASC
LIMIT 10;