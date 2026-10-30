WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
ActiveCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    ac.c_name,
    ss.s_name,
    li.revenue,
    li.item_count,
    COALESCE(ss.part_count, 0) AS part_count,
    CASE 
        WHEN r.total_price_rank = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_category
FROM 
    RankedOrders r
JOIN 
    ActiveCustomers ac ON r.o_orderkey = ac.c_custkey
LEFT JOIN 
    SupplierStats ss ON r.o_orderkey = ss.s_suppkey  
JOIN 
    LineItemSummary li ON r.o_orderkey = li.l_orderkey
WHERE 
    r.total_price_rank <= 5
ORDER BY 
    r.o_totalprice DESC, ac.total_spent DESC;