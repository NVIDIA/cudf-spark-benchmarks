
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
SupplierRanked AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supply_rank
    FROM 
        partsupp ps
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_item_value,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(COALESCE(ps.ps_availqty, 0)) AS total_avail_qty
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    ns.n_name,
    ns.r_name,
    cs.c_name,
    cs.total_spent,
    cs.order_count,
    SUM(COALESCE(ls.total_line_item_value, 0)) AS total_line_item_value,
    SUM(COALESCE(ps.ps_supplycost, 0) * ps.ps_availqty) AS total_supply_value,
    MAX(rop.o_totalprice) AS max_order_price
FROM 
    NationRegion ns
JOIN 
    CustomerSummary cs ON ns.n_nationkey = cs.c_custkey
LEFT JOIN 
    LineItemSummary ls ON cs.c_custkey = ls.l_orderkey
LEFT JOIN 
    SupplierRanked ps ON ns.n_nationkey = ps.ps_suppkey
LEFT JOIN 
    RankedOrders rop ON cs.order_count = rop.o_orderkey
WHERE 
    ns.supplier_count > 5
GROUP BY 
    ns.n_name, ns.r_name, cs.c_name, cs.total_spent, cs.order_count
HAVING 
    MAX(ps.ps_supplycost) < 1000
ORDER BY 
    ns.n_name, total_spent DESC;
