
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(t.total_price, 0) AS total_line_item_price,
    COALESCE(SUM(d.s_acctbal), 0) AS total_supplier_balance,
    CASE 
        WHEN r.rank <= 10 THEN 'TOP ORDER'
        ELSE 'OTHER ORDER'
    END AS order_category
FROM 
    RankedOrders r
LEFT JOIN 
    TotalLineItems t ON r.o_orderkey = t.l_orderkey
LEFT JOIN 
    SupplierDetails d ON d.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 25))
WHERE 
    d.supplier_rank <= 5
GROUP BY 
    r.o_orderkey,
    r.o_orderdate,
    t.total_price,
    r.rank
ORDER BY 
    r.o_orderdate DESC, order_category;
