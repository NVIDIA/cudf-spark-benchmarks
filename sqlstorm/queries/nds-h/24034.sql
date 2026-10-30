WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate IS NOT NULL
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        CASE 
            WHEN r.total_revenue >= (SELECT AVG(total_revenue) FROM RankedOrders) THEN 'High Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank = 1
),
SupplierStats AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
RegionSummary AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(c.c_acctbal) AS total_acct_balance
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    r.nation_name,
    COALESCE(s.supplier_count, 0) AS supplier_count,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    h.value_category,
    ROW_NUMBER() OVER (ORDER BY r.total_acct_balance DESC) AS regional_rank
FROM 
    RegionSummary r
LEFT JOIN 
    SupplierStats s ON r.nation_name = s.s_name
LEFT JOIN 
    HighValueOrders h ON r.nation_name = h.value_category 
WHERE 
    r.customer_count > 10
ORDER BY 
    r.nation_name;
