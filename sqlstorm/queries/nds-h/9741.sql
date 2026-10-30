WITH NationwideSupplierStats AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
        AND ps.ps_availqty > 50
), 
OrderRevenue AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    n.nation_name,
    n.total_suppliers,
    n.total_account_balance,
    n.avg_account_balance,
    p.p_name AS high_value_part,
    p.p_retailprice,
    o.o_orderkey,
    o.total_revenue
FROM 
    NationwideSupplierStats n
LEFT JOIN 
    HighValueParts p ON n.nation_name LIKE '%' || p.p_name || '%'
LEFT JOIN 
    OrderRevenue o ON o.total_revenue > 1000
ORDER BY 
    n.total_suppliers DESC, 
    o.total_revenue DESC
LIMIT 10;