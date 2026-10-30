WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 50000 AND 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 10
),
NationStatistics AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
FinalResults AS (
    SELECT 
        ci.c_name,
        ns.n_name,
        COUNT(DISTINCT h.o_orderkey) AS high_value_orders,
        SUM(h.o_totalprice) AS total_high_value
    FROM 
        CustomerOrderInfo ci
    JOIN 
        HighValueOrders h ON ci.order_count > 5
    JOIN 
        supplier s ON ci.c_custkey = s.s_nationkey
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
    GROUP BY 
        ci.c_name, ns.n_name
)

SELECT 
    fr.c_name,
    fr.n_name,
    fr.high_value_orders,
    fr.total_high_value,
    ns.supplier_count,
    ns.avg_account_balance,
    COALESCE(r.total_avail_qty, 0) AS total_supplied_qty,
    CASE WHEN fr.total_high_value > 250000 THEN 'VIP' ELSE 'Regular' END AS customer_segment
FROM 
    FinalResults fr
LEFT JOIN  
    NationStatistics ns ON fr.n_name = ns.n_name
LEFT JOIN 
    RankedSuppliers r ON r.rank = 1
WHERE 
    fr.high_value_orders > 3 
    AND (fr.n_name IS NULL OR fr.n_name LIKE '%land%')
ORDER BY 
    fr.total_high_value DESC NULLS LAST;