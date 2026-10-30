WITH  CustomerOrderCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) as total_avail_qty,
        COUNT(DISTINCT p.p_partkey) as total_parts,
        AVG(ps.ps_supplycost) as avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) as num_suppliers,
        SUM(s.s_acctbal) as total_acctbal
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    ss.total_avail_qty,
    ss.total_parts,
    ss.avg_supply_cost,
    ns.n_name,
    ns.r_name,
    ns.total_acctbal
FROM 
    CustomerOrderCTE co
LEFT JOIN 
    SupplierStats ss ON co.o_orderkey = ss.s_suppkey  
LEFT JOIN 
    NationSummary ns ON ss.total_parts > 5 AND ns.num_suppliers IS NOT NULL
WHERE 
    co.rn = 1 OR ss.avg_supply_cost IS NULL
ORDER BY 
    co.o_orderdate DESC, co.c_name ASC;