WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.total_account_balance,
    ss.s_name,
    ss.total_available,
    ss.avg_supply_cost,
    od.total_price
FROM 
    NationSummary ns
LEFT JOIN 
    SupplierStats ss ON ns.supplier_count > 0 AND ss.total_parts > 0
LEFT JOIN 
    OrderDetails od ON ns.n_nationkey = od.o_custkey
WHERE 
    ss.total_available IS NOT NULL 
    AND od.total_price > (
        SELECT 
            AVG(total_price) 
        FROM 
            OrderDetails
    )
ORDER BY 
    ns.total_account_balance DESC, 
    ss.avg_supply_cost ASC;
