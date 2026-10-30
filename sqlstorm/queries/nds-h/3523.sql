
WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerRanks AS (
    SELECT 
        c.c_custkey,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
)
SELECT 
    r.r_name,
    SUM(ss.total_parts) AS total_parts_supplied,
    SUM(ss.total_supply_value) AS total_value_supplied,
    COALESCE(COUNT(DISTINCT cr.c_custkey), 0) AS total_top_customers,
    COALESCE(SUM(os.total_lines), 0) AS total_order_lines
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    CustomerRanks cr ON n.n_nationkey = cr.c_nationkey AND cr.rank_by_total <= 5
LEFT JOIN 
    OrderSummary os ON cr.c_custkey = os.o_custkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_value_supplied DESC, 
    total_parts_supplied DESC;
