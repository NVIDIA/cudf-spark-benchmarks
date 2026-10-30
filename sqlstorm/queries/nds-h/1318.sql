
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
NationSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate <= '1996-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    ns.n_name AS supplier_nation,
    hp.p_name AS high_value_part,
    ls.total_lineitem_value,
    ns.avg_account_balance,
    CASE 
        WHEN r.o_orderstatus = 'F' THEN 'Completed'
        ELSE 'Pending'
    END AS order_status,
    COALESCE(hp.total_value, 0) AS part_value_estimate
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemSummary ls ON r.o_orderkey = ls.l_orderkey
LEFT JOIN 
    NationSuppliers ns ON r.o_orderkey % 5 = ns.n_nationkey 
LEFT JOIN 
    HighValueParts hp ON hp.p_partkey = (SELECT p.p_partkey 
                                          FROM part p 
                                          ORDER BY p.p_retailprice DESC
                                          LIMIT 1)
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice;
