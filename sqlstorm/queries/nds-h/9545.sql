WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice 
    FROM 
        customer c 
    JOIN 
        orders o 
    ON 
        c.c_custkey = o.o_custkey
), 
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available_quantity, 
        AVG(ps.ps_supplycost) AS avg_supply_cost 
    FROM 
        partsupp ps 
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
), 
OrderLineDetail AS (
    SELECT 
        lo.l_orderkey, 
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue, 
        AVG(lo.l_tax) AS avg_tax_rate 
    FROM 
        lineitem lo 
    GROUP BY 
        lo.l_orderkey
), 
NationRegionSummary AS (
    SELECT 
        n.n_nationkey, 
        r.r_regionkey, 
        COUNT(n.n_nationkey) AS nation_count 
    FROM 
        nation n 
    JOIN 
        region r 
    ON 
        n.n_regionkey = r.r_regionkey 
    GROUP BY 
        n.n_nationkey, 
        r.r_regionkey
)
SELECT 
    co.c_custkey, 
    co.c_name, 
    SUM(ol.total_revenue) AS total_revenue_per_customer, 
    SUM(ps.total_available_quantity) AS total_qty_available, 
    nr.nation_count 
FROM 
    CustomerOrders co 
JOIN 
    OrderLineDetail ol 
ON 
    co.o_orderkey = ol.l_orderkey 
JOIN 
    PartSupplierInfo ps 
ON 
    co.o_orderkey = ps.ps_partkey 
JOIN 
    NationRegionSummary nr 
ON 
    co.c_nationkey = nr.n_nationkey 
GROUP BY 
    co.c_custkey, 
    co.c_name, 
    nr.nation_count 
HAVING 
    SUM(ol.total_revenue) > 10000 
ORDER BY 
    total_revenue_per_customer DESC;
