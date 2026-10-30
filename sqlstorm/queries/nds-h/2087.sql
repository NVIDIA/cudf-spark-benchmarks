WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_items
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(ls.total_revenue, 0) AS total_revenue,
    ss.total_supply_cost,
    CASE 
        WHEN r.rank <= 5 THEN 'High Priority'
        ELSE 'Standard'
    END AS priority_level
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemSummary ls ON r.o_orderkey = ls.l_orderkey
LEFT JOIN 
    SupplierCosts ss ON ss.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
        WHERE s.s_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = (
                SELECT MAX(n2.n_regionkey) 
                FROM nation n2 
                WHERE n2.n_name LIKE '%land%'
            )
        )
    )
WHERE 
    r.o_orderstatus IN ('F', 'O')
ORDER BY 
    r.o_orderdate DESC, priority_level;