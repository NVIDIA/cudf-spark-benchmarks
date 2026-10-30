WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        s.s_name AS supplier_name,
        s.s_nationkey,
        n.n_name AS nation_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    pd.p_brand,
    pd.p_type,
    SUM(oli.total_revenue) AS total_revenue,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    AVG(co.c_acctbal) AS average_account_balance
FROM 
    PartDetails pd
JOIN 
    OrderLineItems oli ON pd.p_partkey = oli.o_orderkey
JOIN 
    CustomerOrders co ON oli.o_orderkey = co.o_orderkey
WHERE 
    pd.p_size > 10 AND
    pd.p_retailprice < 200.00
GROUP BY 
    pd.p_brand, pd.p_type
ORDER BY 
    total_revenue DESC, customer_count DESC;
