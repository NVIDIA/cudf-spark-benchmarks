
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name) AS nation_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name AS nation_name,
    rs.total_available_qty,
    rs.total_supply_cost,
    os.total_price,
    os.lineitem_count
FROM 
    NationRegion ns
LEFT JOIN 
    SupplierStats rs ON ns.n_nationkey = rs.s_suppkey
LEFT JOIN 
    OrderSummary os ON ns.n_nationkey = os.o_custkey
WHERE 
    (rs.total_supply_cost IS NOT NULL OR os.total_price > 1000)
    AND ns.nation_rank <= 5
ORDER BY 
    ns.r_name, os.total_price DESC NULLS LAST;
