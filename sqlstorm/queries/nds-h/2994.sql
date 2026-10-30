WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),

SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),

OrderDetails AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(*) AS lineitem_count
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        li.l_orderkey
)

SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(rd.total_revenue, 0) AS total_revenue,
    COALESCE(ss.total_parts, 0) AS supplier_part_count,
    ss.avg_acct_balance AS supplier_avg_acct_balance
FROM 
    RankedOrders o
LEFT JOIN 
    OrderDetails rd ON o.o_orderkey = rd.l_orderkey
LEFT JOIN 
    SupplierSummary ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_container = 'BOX'
    )
WHERE 
    o.order_rank <= 5
ORDER BY 
    o.o_orderdate DESC, o.o_orderkey;