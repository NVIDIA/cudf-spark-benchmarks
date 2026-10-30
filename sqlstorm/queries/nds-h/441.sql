WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_parts,
        ss.total_available_qty,
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_available_qty > 0
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
NationRanks AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        NTILE(5) OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    t.s_suppkey,
    t.s_name,
    od.total_order_value,
    nt.n_name AS nation_name,
    t.rank,
    CASE 
        WHEN od.lineitem_count > 5 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS order_volume_category,
    COALESCE(nt.nation_rank, 0) AS nation_rank
FROM 
    TopSuppliers t
LEFT JOIN 
    OrderDetails od ON t.s_suppkey = od.o_custkey
LEFT JOIN 
    NationRanks nt ON t.s_suppkey = nt.n_nationkey
WHERE 
    t.rank <= 10 
ORDER BY 
    t.total_supply_cost DESC, od.total_order_value DESC;
