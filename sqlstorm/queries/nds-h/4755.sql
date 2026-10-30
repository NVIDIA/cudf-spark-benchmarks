WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY c.c_acctbal DESC) AS region_rank
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sr.s_name AS supplier_name,
    os.total_revenue,
    cr.nation_name,
    SUM(cr.c_acctbal) AS total_acct_balance,
    COALESCE(MAX(sr.total_available_qty), 0) AS max_available_quantity,
    CASE 
        WHEN COUNT(DISTINCT os.o_custkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status
FROM 
    SupplierStats sr
LEFT JOIN 
    OrderSummary os ON sr.s_suppkey = os.o_custkey
LEFT JOIN 
    CustomerRegions cr ON os.o_custkey = cr.c_custkey
WHERE 
    cr.region_rank <= 5
GROUP BY 
    sr.s_name, os.total_revenue, cr.nation_name
HAVING 
    SUM(cr.c_acctbal) > 10000
ORDER BY 
    total_revenue DESC, supplier_name;
